(* Copyright (c) 2016-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree. *)

open OUnit2
open IntegrationTest

let test_final_methods context =
  let assert_type_errors = assert_type_errors ~context in
  assert_type_errors
    {|
        from typing import final
        class Foo:
          @final
          def bar(self) -> None:
            pass
        class Bar(Foo):
          def bar(self) -> None:
            pass
      |}
    ["Invalid override [40]: `test.Bar.bar` cannot override final method defined in `Foo`."];
  assert_type_errors
    {|
     from typing import final
     class Foo:
       @final
       def bar(self) -> None:
         pass
     class Bar(Foo):
       def bar(self) -> None:
         pass
   |}
    ["Invalid override [40]: `test.Bar.bar` cannot override final method defined in `Foo`."];
  assert_type_errors
    {|
        from typing import final

        @final
        def foo() -> None:
          pass
      |}
    ["Invalid inheritance [39]: `final` cannot be used with non-method functions."];
  assert_type_errors
    {|
        from typing import final

        class A:
          @final
          def foo(self) -> None:
            pass
      |}
    []


let test_final_class context =
  assert_type_errors
    ~context
    {|
    from typing import final
    @final
    class A:
        pass
    class B(A):
        pass
  |}
    ["Invalid inheritance [39]: Cannot inherit from final class `A`."]


let test_final_attributes context =
  let assert_type_errors = assert_type_errors ~context in
  assert_type_errors
    {|
      from typing import Final
      class A:
        x: Final[int] = 0
      class B(A):
        x = 200
    |}
    ["Invalid assignment [41]: Cannot reassign final attribute `x`."];
  assert_type_errors
    {|
      from typing import List, Final
      x: List[Final[int]] = []
    |}
    [
      "Invalid type [31]: Expression `List[Final[int]]` is not a valid type. Final cannot be nested.";
    ];
  assert_type_errors
    {|
      from typing import Final

      class A:
        def foo(self, x: Final[int]) -> None:
          pass
    |}
    ["Invalid type [31]: Parameter `x` cannot be annotated with Final."];
  assert_type_errors
    {|
      from typing import Final

      def foo(x: Final[int]) -> None:
          pass
    |}
    ["Invalid type [31]: Parameter `x` cannot be annotated with Final."];
  assert_type_errors
    ~concise:true
    {|
      from typing import List, Final
      x: List[Final[int]] = []
    |}
    [
      "Invalid type [31]: Expression `List[Final[int]]` is not a valid type. Final cannot be nested.";
    ];
  assert_type_errors
    ~concise:true
    {|
      from typing import Final, List
      class A:
          def foo(self, x:Final[int]) -> None:
              pass
    |}
    ["Invalid type [31]: Parameter `x` cannot be annotated with Final."];
  assert_type_errors
    {|
      from typing_extensions import Final
      class C:
          def __init__(self) -> None:
              self.x: Final[int] = 1

          def foo(self) -> None:
              self.x = 100
    |}
    ["Invalid assignment [41]: Cannot reassign final attribute `self.x`."];
  assert_type_errors
    {|
      from typing import Final
      class C:
          def __init__(self) -> None:
              self.x: Final[int] = 1

      C.x = 100
    |}
    ["Invalid assignment [41]: Cannot reassign final attribute `C.x`."];
  assert_type_errors
    {|
      from typing import ClassVar
      from typing_extensions import Final
      class z:
          def __init__(self) -> None:
              self.a = "asdf"
      class x:
          y: Final[ClassVar[z]] = z()
      reveal_type(x.y.a)
      x.y = z()
    |}
    [
      "Revealed type [-1]: Revealed type for `test.x.y.a` is `str`.";
      "Invalid assignment [41]: Cannot reassign final attribute `x.y`.";
    ]


let () =
  "final"
  >::: [
         "final_methods" >:: test_final_methods;
         "final_classes" >:: test_final_class;
         "final_attributes" >:: test_final_attributes;
       ]
  |> Test.run
