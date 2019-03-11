//
//  Reader.swift
//  step1_read_print
//
//  Created by steve algernon on 3/11/19.
//  Copyright © 2019 Steve Algernon. All rights reserved.
//

import Foundation

class Token : CustomDebugStringConvertible {
	init(_ s: String) {
		_string = s;
	}
	var _string : String;

	class func parse(_ s: String) -> Token {
		let t = Token(s);
		return t;
	}

	var debugDescription: String {
		return "Token[\(_string)]";
	}
};

class MalType : CustomDebugStringConvertible {
	var debugDescription: String {
		return "__empty_type__";
	}

	func toString() -> String {
		return "### BAD ####";
	}
};

class MalNil : MalType {
	override var debugDescription: String {
		return "nil_type";
	}
	override func toString() -> String {
		return "nil";
	}
};

class MalString : MalType {
	init(_ s: String) {
		_string = s;
	}
	var _string : String;
	override var debugDescription: String {
		return "string_type[\(_string)]";
	}
	override func toString() -> String {
		return _string;
	}
}

class MalList : MalType {
	init(_ e: [MalType]) {
		_elems = e;
	}
	var _elems : [MalType];
	override var debugDescription: String {
		let s = (_elems as NSArray).componentsJoined(by: ",");
		return "list_type[\(s)]";
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
			return "()";
		} else {
			return "(" + s! + ")";
		}
	}
};

class Reader {
	init(_ t: [Token]) {
		_tokens = t;
		_pos = 0;
	}

	var _tokens : [Token];
	var _pos : Int;

	func peek() -> Token? {
		if (_pos >= _tokens.count) {
			return nil;
		}
		return _tokens[_pos];
	}

	func next() -> Token {
		let t = _tokens[_pos];
		_pos = _pos + 1;
		return t;
	}

	class func read_str(_ s: String) -> MalType {
		let t = tokenize(s);
		let r = Reader(t);
		let f = read_form(r);

//		print("Parsed out as: \(f)");

		return f;
	}

	// Add the function read_form to reader.qx. This function will peek at the first
	// token in the Reader object and switch on the first character of that token.
	// If the character is a left paren then read_list is called with the Reader object.
	// Otherwise, read_atom is called with the Reader Object. The return value from
	// read_form is a mal data type. If your target language is statically typed then
	// you will need some way for read_form to return a variant or subclass type. For
	// example, if your language is object oriented, then you can define a top level
	// MalType (in types.qx) that all your mal data types inherit from. The MalList type
	// (which also inherits from MalType) will contain a list/array of other MalTypes.
	// If your language is dynamically typed then you can likely just return a plain
	// list/array of other mal types.


	class func read_form(_ r: Reader) -> MalType {
		let l = r.peek();
		guard l != nil else {
			print("Bad form: \(r)");
			return MalNil();
		}

		if (l!._string == "(") {
			return read_list(r);
		} else {
			return read_atom(r);
		}
	}

	// Add the function read_list to reader.qx. This function will
	// repeatedly call read_form with the Reader object until it
	// encounters a ')' token (if it reach EOF before reading a ')'
	// then that is an error). It accumulates the results into a List
	// type. If your language does not have a sequential data type that
	// can hold mal type values you may need to implement one (in types.qx).
	// Note that read_list repeatedly calls read_form rather than read_atom.
	// This mutually recursive definition between read_list and read_form is
	// what allows lists to contain lists.

	class func read_list(_ r: Reader) -> MalType {
		var l : [MalType] = [];

		_ = r.next();

		while (true) {
			let t = r.peek();
			if (t == nil) {
				print("Parse error: \(r)");
				break;
			}
			if (t!._string == ")") {
				_ = r.next();
				break;
			}
			l.append(read_form(r));
		}

		return MalList(l);
	}

	class func read_atom(_ r: Reader) -> MalType {
		return MalString(r.next()._string);
	}

	class func tokenize(_ s: String) -> [Token] {
//		let str = "[\\s,]*(~@|[\\[\\]{}()'`~^@]|\"(?:\\\\.|[^\\\\\"])*\"?|;.*|[^\\s\\[\\]{}('\"`,;)]*)";
		let str = "[\\s,]*(~@|[\\[\\]{}()'`~^@]|\"(?:\\\\.|[^\\\\\"])*\"?|;.*|[^\\s\\[\\]{}('\"`,;)]*)";
		let n = try! NSRegularExpression.init(pattern: str, options: []);
		let matches = n.matches(in: s, options: [], range: NSRange(location:0, length:s.count));

		var tokens : [Token] = [];

		for m in matches {
			let ss = (s as NSString).substring(with: m.range);
			let st = ss.trimmingCharacters(in: CharacterSet.whitespaces);
//			print("MATCH[\(st)]");
			tokens.append(Token.parse(st));
		}

		return tokens;
	}
};

class Printer {
	class func pr_str(_ m: MalType) {
		let s = m.toString();
		print("\(s)");
	}
};
