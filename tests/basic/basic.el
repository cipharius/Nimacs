(require 'ert)
(require 'libbasic)

(ert-deftest test-basic-return ()
  (should (not (nim-ident 'symbol)))
  (should (equal (nim-ident 'test) "This is emacs function call test")))
