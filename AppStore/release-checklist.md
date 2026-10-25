# Public release checklist

This checklist covers reproducible source, metadata, and build verification.
It intentionally excludes App Store Connect review workflow and account
operations.

## Source and licenses

- [ ] Confirm the release tag points to the intended source commit.
- [ ] Run `swift test`.
- [ ] Run `AyamiIOS` unit and UI tests on iPhone and iPad destinations.
- [ ] Run the same 1.3 tests on both iPhone Duo displays. Check document
      continuity, outline controls, settings, and physical rotation in Device Hub.
- [ ] Test the Files document browser and file-provider updates on real devices.
- [ ] Verify text-size persistence, reset, Dynamic Type, and diagram reflow.
- [ ] Review `Package.resolved` and `swift package show-dependencies`.
- [ ] Verify `THIRD_PARTY_NOTICES.md` and bundled license texts.
- [ ] Confirm the app remains read-only and does not transmit documents.

## Public App Store material

- [ ] Run `./Scripts/verify-app-store-metadata.sh`.
- [ ] Review English and Japanese product-page text.
- [ ] Verify Ayami / あやみ display names and the new bright reading-stand icon.
- [ ] Replace screenshots from the former MD Viewer release.
- [ ] Verify the Marketing, Support, and Privacy Policy URLs.
- [ ] Use only public `Sample.md` or `AppStore/Samples/` content in screenshots.
- [ ] Capture the production app, not the separate UI-test host. Check each
      locale, device size, opaque image format, and finished Mermaid rendering.
- [ ] Confirm no review status, contact details, submission identifiers, or
      private documents are tracked.

## Build

App Store archives (Apple signing credentials required):

```sh
./Scripts/archive-app-store.sh
./Scripts/verify-app-store-export.sh
./Scripts/archive-ios-app-store.sh
./Scripts/verify-ios-app-store-export.sh
```

Only after verifying the intended archives, upload with
`./Scripts/upload-app-store.sh` and `./Scripts/upload-ios-app-store.sh`.
These upload builds; they do not submit the app for review.

- [ ] Run `./Scripts/generate-xcode-project.sh`.
- [ ] Archive the `Ayami` scheme for Any Mac.
- [ ] Export the Mac App Store package.
- [ ] Run `./Scripts/verify-app-store-export.sh`.
- [ ] Run `./Scripts/archive-ios-app-store.sh` and
      `./Scripts/verify-ios-app-store-export.sh`.
- [ ] Confirm both archives use the same marketing version and build number;
      keep `manageAppVersionAndBuildNumber` disabled in export/upload options.
- [ ] Record source and release checksums with the GitHub Release.

## GitHub source release

- [ ] Keep old tags/releases unchanged; create `v1.3` at the intended reviewed commit.
- [ ] Keep the tested product-code commit explicit when the tag also contains later documentation updates.
- [ ] Use `docs/releases/1.3.md` as the release-note source and verify its links after publishing the tag.
- [ ] Attach only the source archive and its checksum; never attach profiles, signing identities, or private records.
- [ ] Download the published assets and verify `SHA256SUMS` and the tag commit.
- [ ] Check that GitHub Pages publishes the updated documentation.

For an already-created local tag:

```sh
git archive --format=tar --prefix=ayami-1.3/ v1.3 | gzip -n > dist/ayami-1.3-source.tar.gz
shasum -a 256 dist/ayami-1.3-source.tar.gz
```

The distributed `SHA256SUMS` must use the archive basename (no local directory),
so it works alongside the downloaded archive. GitHub source publication does
not assert that the App Store version is already available.

App Store Connect remains the source of truth for upload, review, availability,
pricing, and release state.
