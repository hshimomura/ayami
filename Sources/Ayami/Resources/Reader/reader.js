/* Ayami's reading state lives only in this page. No storage, network, or file writes. */
(() => {
  'use strict';
  const article = document.getElementById('document');
  const dialog = document.getElementById('diagram-dialog');
  const expanded = document.getElementById('diagram-expanded');
  let labels = {}, marks = [], selection = null, activeMark = null;
  let corpus = { text: '', nodes: [] }, matches = [], matchIndex = -1, query = '';
  let generation = 0, interaction = 0, lastSource = null, lastTheme = null, lastFormat = null, lastLanguage = null, ready = false;
  let headings = [], diagramScale = 1, diagramWidth = 800, selectionTimer, nativeLinkMenu = false;
  const post = body => window.webkit?.messageHandlers.reader?.postMessage(body);
  const status = () => post({ type: 'state', markCount: marks.length, hasSelection: !!selection,
    hasActiveMark: !!activeMark, matchCount: matches.length, matchIndex,
    matchLimitReached: matches.length === 10000 });

  const md = markdownit({ html: true, linkify: false, typographer: false });
  md.validateLink = href => !/^[\s\u0000-\u001f]*(javascript|vbscript|data):/i.test(href);
  const contentPrefix = 'reader-content-';
  const allowedTags = 'a abbr b bdi bdo blockquote br caption cite code col colgroup dd del details dfn div dl dt em figcaption figure h1 h2 h3 h4 h5 h6 hr i img ins kbd li mark ol p pre q rp rt ruby s samp small span strong sub summary sup table tbody td tfoot th thead time tr u ul var wbr'.split(' ');
  const allowedStyles = new Set('color background-color font-family font-size font-weight font-style text-decoration text-align vertical-align white-space border border-color border-width border-style border-collapse padding padding-top padding-right padding-bottom padding-left margin margin-top margin-right margin-bottom margin-left width max-width min-width height max-height'.split(' '));

  function sanitizedContent(source) {
    const fragment = DOMPurify.sanitize(source, {
      ALLOWED_TAGS: allowedTags,
      ALLOWED_ATTR: ['href', 'src', 'alt', 'title', 'id', 'class', 'style', 'colspan', 'rowspan', 'align', 'width', 'height', 'start', 'reversed', 'open', 'lang', 'dir', 'scope'],
      ALLOW_DATA_ATTR: false, ALLOW_ARIA_ATTR: false, RETURN_DOM_FRAGMENT: true,
      ALLOWED_URI_REGEXP: /^(?:(?:https?|mailto|file):|[^a-z]|[a-z+.\-]+(?:[^a-z+.\-:]|$))/i
    });
    for (const element of fragment.querySelectorAll('*')) {
      // Authored IDs cannot replace the reader's controls or globals.
      if (element.id) element.id = contentPrefix + element.id;
      const language = [...element.classList].find(c => /^language-[a-z0-9+-]+$/i.test(c));
      const mermaid = element.classList.contains('mermaid');
      element.removeAttribute('class');
      if (element.tagName === 'CODE' && language) element.classList.add(language);
      if (['PRE', 'CODE'].includes(element.tagName) && mermaid) element.classList.add('language-mermaid');
      if (element.hasAttribute('style')) {
        for (const property of [...element.style]) {
          if (!allowedStyles.has(property)) element.style.removeProperty(property);
        }
      }
    }
    for (const image of fragment.querySelectorAll('img')) {
      const original = image.getAttribute('src') || '';
      image.dataset.original = original;
      image.removeAttribute('src');
      const isLocal = original && !/^(?:[a-z][a-z0-9+.-]*:|\/\/)/i.test(original) || /^file:/i.test(original);
      if (isLocal) image.setAttribute('src', `ayami-asset://document/image?path=${encodeURIComponent(original)}`);
      else if (/^data:image\/(png|jpeg|gif|webp);base64,[a-z0-9+/=\s]+$/i.test(original) && original.length < 28 * 1024 * 1024) image.setAttribute('src', original);
      else image.classList.add('image-unavailable');
    }
    return fragment;
  }

  function decorateContent() {
    for (const table of article.querySelectorAll('table')) {
      const wrapper = document.createElement('div'); wrapper.className = 'table-scroll';
      table.replaceWith(wrapper); wrapper.append(table);
    }
    for (const pre of article.querySelectorAll('pre')) {
      let code = pre.querySelector('code');
      if (!code) { code = document.createElement('code'); code.textContent = pre.textContent; pre.replaceChildren(code); }
      const languageClass = [...code.classList, ...pre.classList].find(c => c.startsWith('language-'));
      const language = languageClass?.slice(9) || '';
      const source = code.textContent;
      if (language.toLowerCase() === 'mermaid') {
        const figure = document.createElement('figure'); figure.className = 'mermaid-block'; figure.id = pre.id;
        const header = document.createElement('header'); header.dataset.readerUi = '';
        const label = document.createElement('span'); label.textContent = 'Mermaid';
        const expand = document.createElement('button'); expand.type = 'button'; expand.dataset.expand = ''; expand.textContent = labels.expand;
        header.append(label, expand);
        const diagram = document.createElement('div'); diagram.className = 'diagram'; diagram.dataset.source = source;
        const fallback = document.createElement('pre'); fallback.textContent = source; diagram.append(fallback);
        figure.append(header, diagram); pre.replaceWith(figure);
      } else {
        // Syntax highlighting is optional for very large source files; all text remains present.
        const grammar = window.Prism?.languages[language];
        if (grammar && source.length <= 1_048_576) { try { code.innerHTML = Prism.highlight(source, grammar, language); } catch (_) {} }
        const wrapper = document.createElement('div'); wrapper.className = 'code-block';
        const tools = document.createElement('div'); tools.className = 'code-tools'; tools.dataset.readerUi = '';
        const label = document.createElement('span'); label.textContent = language || labels.code;
        const copy = document.createElement('button'); copy.type = 'button'; copy.dataset.copy = ''; copy.textContent = labels.copy;
        tools.append(label, copy); pre.replaceWith(wrapper); wrapper.append(tools, pre);
      }
    }
  }

  function rebuildCorpus() {
    let text = '', nodes = [];
    const walker = document.createTreeWalker(article, NodeFilter.SHOW_TEXT, {
      acceptNode(node) {
        return node.parentElement.closest('[data-reader-ui], svg, .diagram, button') ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT;
      }
    });
    for (let node; (node = walker.nextNode());) {
      nodes.push({ node, start: text.length, end: text.length + node.length });
      text += node.textContent;
    }
    corpus = { text, nodes };
  }
  function textRange(start, end) {
    // Find offsets without rescanning every text node for each search result.
    function nodeAt(offset, inclusive) {
      let low = 0, high = corpus.nodes.length;
      while (low < high) {
        const mid = (low + high) >>> 1, boundary = corpus.nodes[mid].end;
        if (boundary < offset || (!inclusive && boundary === offset)) low = mid + 1;
        else high = mid;
      }
      return corpus.nodes[low];
    }
    const first = nodeAt(start, false), last = nodeAt(end, true);
    if (!first || !last || end <= start) return null;
    const range = document.createRange();
    range.setStart(first.node, Math.max(0, start - first.start));
    range.setEnd(last.node, Math.min(last.node.length, end - last.start));
    return range;
  }
  function offsetAt(node, offset) {
    const found = corpus.nodes.find(n => n.node === node);
    return found ? found.start + offset : null;
  }
  function selectionOffsets(range) {
    // Intersections also handle selections whose endpoints are element nodes.
    let start = null, end = null;
    for (const item of corpus.nodes) {
      if (!range.intersectsNode(item.node)) continue;
      const s = range.startContainer === item.node ? range.startOffset : 0;
      const e = range.endContainer === item.node ? range.endOffset : item.node.length;
      if (e > s) { start ??= item.start + s; end = item.start + e; }
    }
    return start !== null && end > start ? { start, end } : null;
  }
  function paint() {
    if (!window.CSS?.highlights) return;
    // Mutate the registered Highlight so WebKit invalidates its previous ranges.
    // Replacing an existing key with set() can leave stale painted text (WebKit 321567).
    function reset(name) {
      let highlight = CSS.highlights.get(name);
      if (!highlight) { highlight = new Highlight(); CSS.highlights.set(name, highlight); }
      highlight.clear();
      return highlight;
    }
    const pink = reset('ayami-pink'), selected = reset('ayami-selected-mark');
    const found = reset('ayami-find'), current = reset('ayami-current-find');
    for (const mark of marks) { const r = textRange(mark.start, mark.end); if (r) pink.add(r); if (r && mark.id === activeMark) selected.add(r); }
    matches.forEach((match, i) => { const r = textRange(match.start, match.end); if (r) (i === matchIndex ? current : found).add(r); });
  }
  function markSelection() {
    if (!selection) return;
    const { start, end } = selection;
    if (!marks.some(m => m.start === start && m.end === end)) {
      marks.push({ id: crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${marks.length}`, start, end,
        quote: corpus.text.slice(start, end), prefix: corpus.text.slice(Math.max(0, start - 32), start), suffix: corpus.text.slice(end, end + 32) });
    }
    selection = null; activeMark = null;
    window.getSelection().removeAllRanges();
    paint(); status();
  }
  function reanchor(mark, text) {
    const candidates = []; let from = 0;
    while (from <= text.length) {
      const at = text.indexOf(mark.quote, from);
      if (at < 0) break;
      candidates.push(at); from = at + Math.max(1, mark.quote.length);
      if (candidates.length > 1000) return null;
    }
    if (candidates.length === 1) return { ...mark, start: candidates[0], end: candidates[0] + mark.quote.length };
    const exact = candidates.filter(at => text.slice(Math.max(0, at - mark.prefix.length), at) === mark.prefix && text.slice(at + mark.quote.length, at + mark.quote.length + mark.suffix.length) === mark.suffix);
    return exact.length === 1 ? { ...mark, start: exact[0], end: exact[0] + mark.quote.length } : null;
  }
  function find(value, reveal = true) {
    if (reveal) interaction++;
    query = value; matches = []; matchIndex = -1;
    if (value) {
      const regex = new RegExp(value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'giu');
      for (const match of corpus.text.matchAll(regex)) {
        matches.push({ start: match.index, end: match.index + match[0].length });
        if (matches.length === 10000) break;
      }
      if (matches.length) matchIndex = 0;
    }
    paint(); if (reveal) revealMatch(); status();
  }
  function revealMatch() {
    const match = matches[matchIndex]; if (!match) return;
    const range = textRange(match.start, match.end); if (!range) return;
    revealAncestors(range.startContainer.parentElement);
    const rect = range.getBoundingClientRect();
    window.scrollBy({ top: rect.top - innerHeight / 2, behavior: 'instant' });
    // A match can be inside a horizontally scrolling code block or table.
    const scroller = range.startContainer.parentElement.closest('pre, .table-scroll');
    if (scroller) scroller.scrollLeft += rect.left - scroller.getBoundingClientRect().left - 24;
  }
  function revealAncestors(node) {
    for (let parent = node; parent && parent !== article; parent = parent.parentElement) {
      if (parent.tagName === 'DETAILS') parent.open = true;
    }
  }
  function nextMatch(direction) {
    if (!matches.length) return;
    interaction++; matchIndex = (matchIndex + direction + matches.length) % matches.length;
    paint(); revealMatch(); status();
  }
  function assignLocations() {
    const counts = new Map(); headings = [];
    const usedIDs = new Set([...article.querySelectorAll('[id]')].map(node => node.id));
    article.querySelectorAll('h1,h2,h3,h4,h5,h6').forEach(heading => {
      const title = heading.textContent;
      if (!heading.id) {
        const base = title.trim().toLowerCase().replace(/[^\p{L}\p{N}\p{M}\s_-]/gu, '').replace(/\s/g, '-') || 'section';
        let count = counts.get(base) || 0;
        let id = contentPrefix + base + (count ? `-${count}` : '');
        while (usedIDs.has(id)) { count++; id = contentPrefix + base + `-${count}`; }
        counts.set(base, count + 1); usedIDs.add(id); heading.id = id;
      }
      headings.push({ id: heading.id, title, level: Number(heading.tagName[1]) });
    });
    // Exact text keys avoid shifting to a different paragraph when lines are inserted above it.
    const occurrences = new Map();
    article.querySelectorAll('p,pre,table,h1,h2,h3,h4,h5,h6,li,figure').forEach(block => {
      let hash = 2166136261;
      for (const c of block.tagName + block.textContent) { hash ^= c.charCodeAt(0); hash = Math.imul(hash, 16777619); }
      const base = String(hash >>> 0), n = occurrences.get(base) || 0; occurrences.set(base, n + 1);
      block.dataset.readingKey = `${base}-${n}`;
    });
  }
  function capturePosition() {
    const blocks = [...article.querySelectorAll('[data-reading-key]')];
    const visible = blocks.filter(b => b.getBoundingClientRect().bottom > 0 && b.getBoundingClientRect().top < innerHeight);
    return { anchors: visible.slice(0, 5).map(b => ({ key: b.dataset.readingKey, top: b.getBoundingClientRect().top })), y: scrollY, epoch: interaction };
  }
  function restorePosition(saved) {
    if (!saved || saved.epoch !== interaction) return;
    for (const anchor of saved.anchors) {
      const block = article.querySelector(`[data-reading-key="${anchor.key}"]`);
      if (block) { scrollBy(0, block.getBoundingClientRect().top - anchor.top); return; }
    }
    scrollTo(0, saved.y);
  }
  function jump(fragment) {
    interaction++;
    let id; try { id = decodeURIComponent(fragment.replace(/^#/, '')); } catch (_) { id = fragment; }
    const target = id ? [...article.querySelectorAll('[id]')].find(node => node.id === id || node.id === contentPrefix + id) : article;
    if (target && article.contains(target)) { revealAncestors(target); target.scrollIntoView({ block: 'start' }); return true; }
    post({ type: 'anchorMissing' }); return false;
  }
  async function renderDiagrams(sequence, saved, theme) {
    const figures = [...article.querySelectorAll('.diagram')];
    if (!figures.length) return;
    mermaid.initialize({ startOnLoad: false, securityLevel: 'strict', layout: 'dagre', look: 'classic',
      theme: theme === 'dark' ? 'dark' : 'neutral', suppressErrorRendering: true,
      flowchart: { htmlLabels: false } });
    for (const [index, container] of figures.entries()) {
      if (sequence !== generation) return;
      try {
        const result = await mermaid.render(`ayami-${sequence}-${index}`, container.dataset.source);
        if (sequence !== generation) return;
        container.innerHTML = result.svg;
        container.querySelectorAll('a').forEach(link => link.replaceWith(...link.childNodes));
      } catch (_) {
        if (sequence !== generation) return;
        container.querySelector('pre').textContent = labels.diagramError + '\n\n' + container.dataset.source;
        container.closest('figure').querySelector('[data-expand]').disabled = true;
      }
      restorePosition(saved);
    }
  }
  async function update(options) {
    labels = options.labels;
    nativeLinkMenu = options.nativeLinkMenu === true;
    document.documentElement.style.fontSize = `${16 * options.scale}px`;
    document.documentElement.lang = options.language;
    document.documentElement.style.colorScheme = options.theme;
    const changed = options.markdown !== lastSource || options.theme !== lastTheme || options.format !== lastFormat || options.syntaxLanguage !== lastLanguage;
    if (!changed) return;
    post({ type: 'rendering' });
    const saved = ready ? capturePosition() : null;
    const sequence = ++generation; lastSource = options.markdown; lastTheme = options.theme; lastFormat = options.format; lastLanguage = options.syntaxLanguage;
    if (dialog.open) dialog.close();
    if (options.format === 'plainText') {
      const pre = document.createElement('pre'), code = document.createElement('code');
      code.textContent = options.markdown;
      if (/^[a-z0-9+-]+$/i.test(options.syntaxLanguage || '')) code.className = 'language-' + options.syntaxLanguage;
      pre.append(code); article.replaceChildren(pre);
    } else {
      article.replaceChildren(sanitizedContent(options.format === 'html' ? options.markdown : md.render(options.markdown)));
    }
    decorateContent();
    assignLocations(); rebuildCorpus();
    const oldCount = marks.length;
    marks = marks.map(mark => reanchor(mark, corpus.text)).filter(Boolean);
    selection = null; activeMark = null;
    find(query, false);
    if (oldCount > marks.length) post({ type: 'marksRemoved', count: oldCount - marks.length });
    for (const img of article.querySelectorAll('img')) {
      img.addEventListener('error', () => { if (sequence !== generation) return; img.classList.add('image-unavailable'); post({ type: 'imageUnavailable' }); });
      img.addEventListener('load', () => { if (sequence === generation) restorePosition(saved); });
    }
    document.getElementById('diagram-fit').textContent = labels.fit;
    document.getElementById('diagram-close').textContent = labels.close;
    document.getElementById('diagram-plus').setAttribute('aria-label', labels.zoomIn);
    document.getElementById('diagram-minus').setAttribute('aria-label', labels.zoomOut);
    restorePosition(saved); ready = true;
    post({ type: 'ready', headings });
    await renderDiagrams(sequence, saved, options.theme);
    if (sequence === generation) { restorePosition(saved); post({ type: 'diagramsReady' }); }
  }
  function resizeDiagram() {
    expanded.style.width = `${diagramWidth * diagramScale}px`;
    document.getElementById('diagram-scale').textContent = `${Math.round(diagramScale * 100)}%`;
  }
  function expandDiagram(figure) {
    const svg = figure.querySelector('svg'); if (!svg) return;
    expanded.replaceChildren(svg.cloneNode(true));
    dialog.showModal();
    diagramWidth = Math.max(1, dialog.clientWidth - 40); diagramScale = 1; resizeDiagram();
  }
  article.addEventListener('contextmenu', event => {
    const link = event.target.closest('a[href]');
    if (!nativeLinkMenu || !link) return;
    event.preventDefault();
    post({ type: 'linkContextMenu', href: link.getAttribute('href'), x: event.clientX, y: event.clientY });
  });
  article.addEventListener('click', event => {
    const copy = event.target.closest('[data-copy]');
    if (copy) { post({ type: 'copy', text: copy.closest('.code-block').querySelector('code').textContent }); copy.textContent = labels.copied; setTimeout(() => { copy.textContent = labels.copy; }, 1400); return; }
    const enlarge = event.target.closest('[data-expand]');
    if (enlarge) { expandDiagram(enlarge.closest('figure')); return; }
    const link = event.target.closest('a');
    if (link) { event.preventDefault(); const href = link.getAttribute('href'); if (href?.startsWith('#')) jump(href); else post({ type: 'link', href }); return; }
    const caret = document.caretRangeFromPoint?.(event.clientX, event.clientY);
    const at = caret ? offsetAt(caret.startContainer, caret.startOffset) : null;
    activeMark = at === null ? null : marks.find(m => m.start <= at && at < m.end)?.id || null;
    paint(); status();
  });
  document.addEventListener('selectionchange', () => {
    clearTimeout(selectionTimer);
    selectionTimer = setTimeout(() => {
      const selected = window.getSelection();
      if (selected.rangeCount && !selected.isCollapsed && article.contains(selected.anchorNode) && article.contains(selected.focusNode)) {
        selection = selectionOffsets(selected.getRangeAt(0));
      } else if (document.activeElement === document.body || article.contains(document.activeElement)) { selection = null; }
      status();
    }, 50);
  });
  ['wheel', 'touchstart', 'pointerdown', 'keydown'].forEach(name => document.addEventListener(name, () => { interaction++; }, { passive: true }));
  let scrollPending = false;
  document.addEventListener('scroll', () => {
    if (scrollPending) return; scrollPending = true;
    requestAnimationFrame(() => {
      scrollPending = false;
      const current = [...article.querySelectorAll('h1,h2,h3,h4,h5,h6')].filter(h => h.getBoundingClientRect().top <= 80).pop();
      post({ type: 'section', id: current?.id || headings[0]?.id || '' });
    });
  });
  document.getElementById('diagram-plus').onclick = () => { diagramScale = Math.min(4, diagramScale + .25); resizeDiagram(); };
  document.getElementById('diagram-minus').onclick = () => { diagramScale = Math.max(.25, diagramScale - .25); resizeDiagram(); };
  document.getElementById('diagram-fit').onclick = () => { diagramWidth = Math.max(1, dialog.clientWidth - 40); diagramScale = 1; resizeDiagram(); };
  document.getElementById('diagram-close').onclick = () => dialog.close();
  window.reader = { update, find, nextMatch, markSelection, jump,
    removeMark() { marks = marks.filter(m => m.id !== activeMark); activeMark = null; paint(); status(); },
    clearMarks() { marks = []; activeMark = null; paint(); status(); },
    reloadImages() { for (const img of article.querySelectorAll('img[data-original]')) { if (img.src.startsWith('ayami-asset:')) { img.classList.remove('image-unavailable'); const url = new URL(img.src); url.searchParams.set('reload', String(Date.now())); img.src = url.href; } } },
    closeDiagram() { if (dialog.open) dialog.close(); }
  };
  post({ type: 'loaded' });
})();
