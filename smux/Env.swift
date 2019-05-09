import Foundation;

typealias SEnvHash = [ MalSymbol : MalType ];

class SEnv : CustomStringConvertible {
	var _outer : SEnv?;

	var _env : SEnvHash = [ : ];

	init(_ outer:SEnv?) {
		_outer = outer;
	}

	func set(symbol:MalSymbol, value:MalType) -> Void {
		_env[symbol] = value;
	}

	func find(symbol:MalSymbol) -> MalType? {
		var r = _env[symbol];
		if (r == nil && _outer != nil) {
			r = _outer!.find(symbol:symbol);
		}
		return r;
	}

	func get(symbol:MalSymbol) throws -> MalType {
		let r = _env[symbol];
		if (r == nil) {
			throw ReaderError.undefinedSymbol(symbol);
		}
		return r!;
	}

	var description: String {
		let o : String;
		
		if (_outer == nil) {
			o = "no outer";
		} else {
			o = _outer!.description;
		}

		return "{ \(_env) } -> { \(o) }";
	}
}
