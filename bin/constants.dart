enum TokenType {
  keyword,
  symbol,
  identifier,
  intConst,
  stringConst,
}

enum Keyword {
  $class,
  $method,
  $function,
  $constructor,
  $int,
  $boolean,
  $char,
  $void,
  $var,
  $static,
  $field,
  $let,
  $do,
  $if,
  $else,
  $while,
  $return,
  $true,
  $false,
  $null,
  $this,
}

extension Value on Keyword {
  /// Returns the valid string representation of a [Keyword].
  String value() => toString().replaceFirst(r'Keyword.$', '');
}

/// Returns a [Keyword] for a valid string representation, such as "if" or "class".
Keyword getKeywordFromString(List<Keyword> values, String asString) =>
    values.firstWhere((kw) => kw.value() == asString);

const symbols = {
  '(': true,
  ')': true,
  '{': true,
  '}': true,
  '[': true,
  ']': true,
  '.': true,
  ',': true,
  ';': true,
  '+': true,
  '-': true,
  '*': true,
  '/': true,
  '&': true,
  '|': true,
  '"': true,
  '<': true,
  '>': true,
  '=': true,
  '~': true,
};

/// Symbol to html entity map for characters for use in xml translation
const specialSymbols = {
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  '&': '&amp;',
};
