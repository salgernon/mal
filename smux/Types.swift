//
//  Types.swift
//  smux
//
//  Created by steve algernon on 5/3/19.
//  Copyright © 2019 Steve Algernon. All rights reserved.
//

import Foundation

class MalType : CustomDebugStringConvertible, Hashable, Equatable {
	var debugDescription: String {
		return "__empty_type__";
	}

	func toString() -> String {
		return "### BAD ####";
	}

	func toReadable() -> String {
		return toString();
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(self.toString());
	}

	static func == (lhs: MalType, rhs: MalType) -> Bool {
		return lhs.toString().compare(rhs.toString()) == ComparisonResult.orderedSame;
	}
};

class MalNil : MalType {
	static var canonicalString = "nil";

	override var debugDescription: String {
		return "nil_type";
	}
	override func toString() -> String {
		return MalNil.canonicalString;
	}
};

class MalQuote : MalType {
	override var debugDescription: String {
		return "quote";
	}
	override func toString() -> String {
		return "'";
	}
}

class MalQuasiQuote : MalType {
	override var debugDescription: String {
		return "quasiquote";
	}
	override func toString() -> String {
		return "`";
	}
}

class MalSymbol : MalType {
}

class MalString : MalSymbol {
	init(_ s: String) {
		_string = MalString.expand(s);
	}
	var _string : String;
	override var debugDescription: String {
		return "string_type[\(_string)]";
	}
	override func toString() -> String {
		return _string;
	}
	override func toReadable() -> String {
		return MalString.collapse(_string);
	}

	class func expand(_ s: String) -> String {
		let s2 = s.replacingOccurrences(of: "\\n", with: "\n");
		let s3 = s2.replacingOccurrences(of: "\\", with: "");
		return s3;
	}

	class func collapse(_ s: String) -> String {
		return s;
	}
}

class MalKeyword : MalString {
	override init(_ s: String) {
		super.init(s);
	}
	override var debugDescription: String {
		let s = super.toString();
		return "keyword[\(s)]";
	}
	override func toString() -> String {
		let s = super.toString();
		return ":\(s)";
	}
}

class MalScalar : MalSymbol {
	init(_ s: Int) {
		_value = s;
	}
	var _value : Int;
	override var debugDescription: String {
		return "scalar_type[\(_value)]";
	}
	override func toString() -> String {
		return "\(_value)";
	}
	func scalarValue() -> Int {
		return _value;
	}
}

class MalBool : MalType {
	init(_ b: Bool) {
		_value = b;
	}
	var _value : Bool;
}

class MalTrue : MalBool {
	static let canonicalString = "true";

	init() {
		super.init(true);
	}
	override var debugDescription: String {
		return "true_value";
	}
	override func toString() -> String {
		return MalTrue.canonicalString;
	}
}

class MalFalse : MalBool {
	static let canonicalString = "false";

	init() {
		super.init(false);
	}
	override var debugDescription: String {
		return "false_value";
	}
	override func toString() -> String {
		return MalFalse.canonicalString;
	}
}

class MalCollection : MalType {
	class func delims() -> [String] {
		return [];
	}

	required init(_ e: [MalType]) throws {
		_elems = e;
	}

	override init() {
		_elems = [];
	}

	var _elems : [MalType];

	func count() -> Int {
		return _elems.count;
	}
	
	override var debugDescription: String {
		let s = (_elems as NSArray).componentsJoined(by: ",");
		let ll = type(of:self);
		return "col_type_\(ll)[\(s)]";
	}

	override func toString() -> String {
		var s : String? = nil;

		for e in _elems {
			if (s == nil) {
				s = e.toString();
			} else {
				s = s! + " " + e.toString();
			}
		}

		let delims = type(of:self).delims();

		if (s == nil) {
			return delims[0] + delims[1];
		} else {
			return delims[0] + s! + delims[1];
		}
	}

	func map2(_ by: (MalType) throws -> MalType) -> MalType {
		return self;
	}

	func car() -> MalType {
		if (count() == 0) {
			return MalNil();
		}
		return _elems[0];
	}

	func cdr() -> MalList {
		switch (count()) {
			case 0:
				return (self as! MalList);
			case 1:
				return try! MalList([]);
			default:
				return try! MalList(Array(_elems.suffix(from: 1)));
		}
	}

	subscript(elem: Int) -> MalType {
		get {
			return _elems[elem];
		}
	}

	func pop() -> ( MalType, MalList ) {
		let head = _elems[0];
		let rest = cdr();
		return ( head, rest );
	}
}

class MalVector : MalCollection {
	override class func delims() -> [String] {
		return [ "[", "]" ];
	}

	required init(_ e: [MalType]) throws {
		try super.init(e);
	}

	override func map2(_ by: (MalType) throws -> MalType) -> MalType {
#if BB
		let l = try? _elems.map { (m:MalType) -> MalType in
			return try by(m);
		};

		return try! MalVector(l ?? []);
#endif
		let c = count();
		var i = 0;
		var newElems : [MalType] = [];
		while (i < c) {
			let cur = _elems[i];
			i += 1;
			let val = try! by(cur);
			newElems.append(val);
		}
		return try! MalVector(newElems);
	}
}

class MalHash : MalCollection {
	override class func delims() -> [String] {
		return [ "{", "}" ];
	}

	required init(_ e: [MalType]) throws {
		try super.init(e);

		let count = e.count;

		guard count % 2 == 0 else {
			throw ReaderError.oddHashElements(elems:e);
		}

		var i = 0;
		while (i < count) {
			let key = e[i + 0];
			let val = e[i + 1];

			i += 2;

			_map[key] = val;
		}
	}

	var _map : [MalType : MalType] = [:];

	override func map2(_ by: (MalType) throws -> MalType) -> MalType {
		var newMap : [MalType] = [];

		_map.forEach { (key: MalType, value: MalType) in
			newMap.append(key);
			newMap.append(try! by(value));
		}

		return try! MalHash(newMap);
	}
}

class MalList : MalCollection {
	override class func delims() -> [String] {
		return [ "(", ")" ];
	}

	required init(_ e: [MalType]) throws {
		try super.init(e);
	}

	override init() {
		super.init();
	}

	override func map2(_ by: (MalType) throws -> MalType) -> MalType {
#if BB
		let l = try? _elems.map { (m:MalType) -> MalType in
			return try by(m);
		};

		return try! MalList(l ?? []);
#else
		let c = count();
		var i = 0;
		var newElems : [MalType] = [];
		while (i < c) {
			let cur = _elems[i];
			i += 1;
			let val = try? by(cur);
			guard (val != nil) else {
				throw ReaderError.fatalError("failed to evaluate \(cur)");
			}
			newElems.append(val);
		}
		return try! MalVector(newElems);
#endif
	}
}

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

		let cdr = l.cdr();
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
