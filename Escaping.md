## My attempts to escape double square brackets (DSB).

* `[[` some text. Some unrelated `]]`. This is incorrectly turned into a wiki link
* `'[[` some text.  Some unrelated `]]`. Escaping the DSB with a single quote works once.
* `'[[`, `'[[`, `'[[`, `'[[` but if you have multiple DSBs, the quote appears in the second and subsequent DSBs. `]]`

* `[[` - this is ok without escaping because there are no closing DSBs in the rest of the page.

And backslashes appear literally inside backticks:

* `\[[`
* `[\[`

