module base::test{

    #[test_only]
    use std::string;
    #[test_only]
    use std::debug::print;
    /// false
const EFALSE:u64 = 1;

    #[test]
    fun test_assignment(){
        let  test_assignment = string::utf8(b"########################## test assignment ##########################");
        print(&test_assignment);
        let arithmetic = string::utf8(b"----- Assignment 'string' to str, expeced string -----");
        print(&arithmetic);
        let str = string::utf8(b"string");
        print(&str);

        let arithmetic = string::utf8(b"----- Assignment '10' to num, expeced 10 -----");
        print(&arithmetic);
        let num = 10;
        print(&num);

        let arithmetic = string::utf8(b"----- Assignment 'true' to bool, expeced true -----");
        print(&arithmetic);
        let flag = true;
        print(&flag);

    }
    #[test]
    fun test_comparison(){
        let  test_calc = string::utf8(b"########################## test comparison ##########################");
        print(&test_calc);

        let comparison = string::utf8(b"----- Comparison (2 > 3) expected false -----");
        print(&comparison);
        let result = (2 > 3);
        print(&result);

        // assert!( !result,EFALSE);
        let comparison = string::utf8(b"----- Comparison (2 < 3) expected true -----");
        print(&comparison);
        let result = (2 < 3);
        print(&result);

        let comparison = string::utf8(b"----- Comparison (8 <= 3) expected true -----");
        print(&comparison);
        let result = (8 <= 3);
        print(&result);

        let comparison = string::utf8(b"----- Comparison (8 >= 3) expected false -----");
        print(&comparison);
        let result = (8 <= 3);
        print(&result);

        let comparison = string::utf8(b"----- Comparison (2 == 3) expected false -----");
        print(&comparison);
        let result = (2 == 3);
        print(&result);
    }
    #[test]
    fun test_calc() {
        let  test_calc = string::utf8(b"########################## test calc ##########################");
        print(&test_calc);

        let arithmetic = string::utf8(b"----- Arithmetic ( 17 + 5) expected 22-----");
        print(&arithmetic);
        let result = ( 17 + 5);
        print(&result);

        let arithmetic = string::utf8(b"----- Arithmetic ( 17 - 5) expected 12----- [don't (4 - 17), ERROR: Subtraction overflow]");
        print(&arithmetic);
        let result = ( 17 - 5);
        print(&result);

        let arithmetic = string::utf8(b"----- Arithmetic ( 17 * 5) expected 85-----");
        print(&arithmetic);
        let result = ( 17 * 5);
        print(&result);

        let arithmetic = string::utf8(b"----- Arithmetic ( 17 / 5) expected 3-----");
        print(&arithmetic);
        let result = ( 17 / 5);
        print(&result);
        let num = 5;
        print(&num);

        let arithmetic = string::utf8(b"----- Arithmetic ( 17 % 5) expected 2-----");
        print(&arithmetic);
        let result = ( 17 % 5);
        print(&result);

        let arithmetic = string::utf8(b"----- Arithmetic ( 17 | 5) expected 21 [OR]-----");
        print(&arithmetic);
        let result = ( 17 | 5);
        print(&result);
        // 128 64 32 16  8  4  2  1
        //   0  0  0  1  0  0  0  1  ---- 17
        //   0  0  0  0  0  1  0  1  ---- 5
        //   0  0  0  1  0  1  0  1  --- 21
        // 0 OR 0 = 0
        // 0 OR 1 = 1
        // 1 OR 0 = 1
        // 1 OR 1 = 1

        let arithmetic = string::utf8(b"----- Arithmetic ( 17 & 5) expected 1 [AND]-----");
        print(&arithmetic);
        let result = ( 17 & 5);
        print(&result);
        // 128 64 32 16  8  4  2  1
        //   0  0  0  1  0  0  0  1  ---- 17
        //   0  0  0  0  0  1  0  1  ---- 5
        //   0  0  0  0  0  0  0  1  ---- 1
        // 0 OR 0 = 0
        // 0 OR 1 = 0
        // 1 OR 0 = 0
        // 1 OR 1 = 1

        let arithmetic = string::utf8(b"----- Arithmetic ( 17 ^ 5) expected 20 [XOR]-----");
        print(&arithmetic);
        let result = ( 17 ^ 5);
        print(&result);
        // 128 64 32 16  8  4  2  1
        //   0  0  0  1  0  0  0  1  ---- 17
        //   0  0  0  0  0  1  0  1  ---- 5
        //   0  0  0  1  0  1  0  0  ---- 20
        // 0 XOR 0 = 0
        // 0 XOR 1 = 1
        // 1 XOR 0 = 1
        // 1 XOR 1 = 0

        let arithmetic = string::utf8(b"----- Arithmetic !( 17 < 5) expected true [NOT]-----");
        print(&arithmetic);
        let result = !( 17 < 5);
        print(&result);

        let arithmetic = string::utf8(b"----- Arithmetic ( true && false) expected false [Logical AND] -----");
        print(&arithmetic);
        let result = ( true && false);
        print(&result);

        let arithmetic = string::utf8(b"----- Arithmetic ( true || false) expected true [Logical OR] -----");
        print(&arithmetic);
        let result = ( true || false);
        print(&result);

        let arithmetic = string::utf8(b"----- Arithmetic (11 << 2) expected 44 [Left Shift] -----");
        print(&arithmetic);
        let result:u8 = ( 11 << 2);
        print(&result);
        // 128 64 32 16  8  4  2  1
        //   0  0  0  0  1  0  1  1  ---- 11
        //                        ^  ----
        //                  ^  0  0  ---- 2 shift
        //   0  0  1  0  1  1  0  0  ---- 44

        let arithmetic = string::utf8(b"----- Arithmetic (11 >> 2) expected 2 [Right Shift] -----");
        print(&arithmetic);
        let result:u8 = ( 11 >> 2);
        print(&result);
        // 128 64 32 16  8  4  2  1
        //   0  0  0  0  1  0  1  1          ---- 11
        //                        ^          ----
        //   0  0  0  0  0  0  1  0  1  1    ---- 2 shift
        //   0  0  0  0  0  0  1  0          ---- 2

        // -------------

    }
}
