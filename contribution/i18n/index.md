# Internationalization

This documentation describes how to translate the original documentations in English to other languages.

## Work-flow

Here is a work-flow to translate one documentation in English:

  1. Run `rake`.
  2. Translate `_po/${YOUR_LOCALE}/${PATH_TO_TARGET_FILE}.edit.po`.
  3. Run `rake`.
  4. Run `jekyll server`.
  5. Confirm `_site/${YOUR_LOCALE}/${PATH_TO_TARGET_FILE}.html`.
  6. Commit `_po/${YOUR_LOCALE}/${PATH_TO_TARGET_FILE}.po` (not `.edit.po`) and ``${YOUR_LOCALE}/${PATH_TO_TARGET_FILE}.md`.

## Example

Here is an example to translate `overview/index.md` into Japanese.

Run `rake`:

```
% rake
```

Translate `_po/ja/overview/index.edit.po`:

```
% gedit _po/ja/overview/index.edit.po
```

Note: You can use PO editor instead of text editor. For example, Emacs's po-mode, Vim, [Gtranslator](https://wiki.gnome.org/Apps/Gtranslator), [Lokalize](http://userbase.kde.org/Lokalize) and so on.

Run `rake`:

```
% rake
```

Run `jekyll server`:

```
% jekyll server &
```

Confirm `_site/ja/overview/index.html`:

```
% firefox http://localhost:4000/ja/overview/index.html
```

Commit `_po/ja/overview/index.po` and `ja/overview/index.md`:

```
% git add _po/ja/overview/index.po
% git add ja/overview/index.md
% git commit
% git push
```
