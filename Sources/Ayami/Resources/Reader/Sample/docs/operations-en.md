# Notification Service — Operations

[Back to the design review](../README-en.md)

## Daily checks

Check queue depth and delivery success rate. This public sample contains no confidential data.

## Incident response

1. Check the destination and timeout rate.
2. Check retry counts and duplicate request IDs.
3. Resolve the cause before processing notifications in the recovery queue.

```sh
printf '%s\n' 'Check the queue before retrying.'
```
