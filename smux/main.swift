
#if STEP_0
let t = SLisp0();
#elseif STEP_1
let t = SLisp1();
#elseif STEP_2
let t = SLisp2();
#elseif STEP_3
let t = SLisp3();
#else
let t = SLisp();
#endif

print("Hello \(t)");
//t.runt("(+ 1 2)");
t.run();

//t.runt("(1 2, 3,,,,),,")
//t.runt("(1 2");


