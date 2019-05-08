import Foundation;

class MalClosure : MalType {
	func apply(_ l: MalList) throws -> MalType {
		return l;
	}
}

class MalScalarApplyier : MalClosure {
	override func apply(_ l: MalList) throws -> MalType {
		let car = l.car();
		guard type(of:car) == MalScalar.self else {
			throw ReaderError.fatalError("expected scalar as car of \(l)");
		}

		let cdr = try l.cdr();
		if (cdr.count() == 0) {
			return car;
		}

		let lVal = (car as! MalScalar);
		let rVal = try apply(cdr);

		guard type(of:rVal) == MalScalar.self else {
			throw ReaderError.fatalError("expected scalar as result of apply against \(cdr)");
		}

		return try apply(a:lVal, b:(rVal as! MalScalar));
	}

	func apply(a:MalScalar, b:MalScalar) throws -> MalScalar {
		return MalScalar(0);
	}
}

class MalClosure_Add : MalScalarApplyier {
	override func apply(a:MalScalar, b:MalScalar) throws -> MalScalar {
		return MalScalar(a.scalarValue() + b.scalarValue());
	}
}

class MalClosure_Sub : MalScalarApplyier {
	override func apply(a:MalScalar, b:MalScalar) throws -> MalScalar {
		return MalScalar(a.scalarValue() - b.scalarValue());
	}
}

class MalClosure_Mul : MalScalarApplyier {
	override func apply(a:MalScalar, b:MalScalar) throws -> MalScalar {
		return MalScalar(a.scalarValue() * b.scalarValue());
	}
}

class MalClosure_Div : MalScalarApplyier {
	override func apply(a:MalScalar, b:MalScalar) throws -> MalScalar {
		return MalScalar(a.scalarValue() / b.scalarValue());
	}
}

typealias SEnv = [ MalString : MalClosure ];

class MalAst : MalType {
}

class Slisp {
	func READ(_ s: String) throws -> MalType {
		return try Reader.read_str(s)
	}

	func eval_ast(_ ast:MalType, env:SEnv) throws -> MalType {
		if (type(of:ast) == MalString.self) {
			let r = env[ast as! MalString];
			guard (r != nil) else {
				throw ReaderError.undefinedSymbol(ast);
			}
			return r!;
		}

		if (type(of:ast) == MalList.self) {
			return (ast as! MalList).map2({ (v:MalType) -> MalType in
				return try EVAL(v, env:env);
			});
		}

		return ast;
	}

	func EVAL(_ ast: MalType, env:SEnv) throws -> MalType {
		if (type(of:ast) != MalList.self) {
			return try eval_ast(ast, env:env);
		}
		let l = (ast as! MalList);
		if (l.count() == 0) {
			return ast;
		}

		let n = try eval_ast(ast, env:env);
		guard (type(of:ast) == MalList.self) else {
			throw ReaderError.fatalError("expected list in eval_ast of list \(ast)");
		}

		let s = (n as! MalList).car();
		let r = try (n as! MalList).cdr();

		return try (s as! MalClosure).apply(r);
	}

	func PRINT(_ s: MalType) throws -> Void {
		Printer.pr_str(s);
	}

	func rep(_ s: String, env: SEnv) throws -> Void {
		try PRINT(EVAL(READ(s), env:env));
	}

	func runt(_ s: String) -> Void {
		let env : SEnv = [
			MalString("+") : MalClosure_Add(),
			MalString("-") : MalClosure_Sub(),
			MalString("*") : MalClosure_Mul(),
			MalString("/") : MalClosure_Div()
		];

		do {
			// list { sym("+")  1 2 }
			try rep(s, env:env);
		} catch (ReaderError.emptyLine) {
			// just a line with a comment
		} catch (ReaderError.badForm(let r)) {
			print("Bad form: \(r)");
		} catch (ReaderError.fatalError) {
			print("Fatal error");
		} catch (ReaderError.unexepectedEOF(let missing)) {
			print("Unspected EOF, missing \(missing)");
		} catch {
			print("Utter failure evaluating \(s)");
		}
	}
	
	func run() -> Void {
		var running = true;

		while (running) {
			print("user> ", terminator:"");
			let s = readLine(strippingNewline:true);

			if (s == nil || s!.compare("quit") == ComparisonResult.orderedSame) {
				running = false;
			} else {
				runt(s!);
			}
		}
	}
}
