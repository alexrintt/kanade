# Contributing

Welcome! We appreciate your interest in contributing to Kanade ;)

## Feedback

Bug reports, feature requests or doc improvements? Please create an issue on GitHub or send it at our [Discord chat](https://alexrintt.io/r/discord).

## Code Contributions

Feel like fixing a bug or adding a feature? Great! Follow these steps:

1. Fork the repository
2. Create a new branch (`git checkout -b feature/my-feature`)
3. Make your changes.
4. Submit a pull request.

## Development

These are the steps to setup your development environment.

### Requirements

- Flutter >= **3.x.x**.
  - [How to install Flutter?](https://docs.flutter.dev/get-started/install)
- Dart >= **3.x.x**.
  - Use the same from the Flutter SDK.
- GNUMake.
  - Unix user? [GNU Make](https://www.gnu.org/software/make/).
  - Windows user? [How to install and use "make" in Windows?](https://stackoverflow.com/questions/32127524/how-to-install-and-use-make-in-windows).

### Setup

- First-time run:

```
git clone https://github.com/alexrintt/kanade
cd kanade
make setup
```

- Start development mode:

```
make dev -j
```

- After development:

```
make prepush
```
