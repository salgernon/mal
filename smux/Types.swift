//
//  Types.swift
//  smux
//
//  Created by steve algernon on 5/3/19.
//  Copyright © 2019 Steve Algernon. All rights reserved.
//

import Foundation

class MalType : CustomDebugStringConvertible {
	var debugDescription: String {
		return "__empty_type__";
	}

	func toString() -> String {
		return "### BAD ####";
	}

	func toReadable() -> String {
		return toString();
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

class MalString : MalType {
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

class MalScalar : MalType {
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
	init(_ e: [MalType], opening:String, closing:String) {
		_elems = e;
		_opening = opening;
		_closing = closing;
	}
	var _elems : [MalType];
	var _opening : String;
	var _closing : String;

	override var debugDescription: String {
		let s = (_elems as NSArray).componentsJoined(by: ",");
		return "col_type[\(s)]";
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

		if (s == nil) {
			return _opening + _closing;
		} else {
			return _opening + s! + _closing;
		}
	}
}

class MalVector : MalCollection {
	init(_ e: [MalType]) {
		super.init(e, opening: "[", closing: "]");
	}
}

class MalList : MalCollection {
	init(_ e: [MalType]) {
		super.init(e, opening: "(", closing: ")");
	}
}
