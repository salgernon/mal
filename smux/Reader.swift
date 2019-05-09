//
//  Reader.swift
//  step1_read_print
//
//  Created by steve algernon on 3/11/19.
//  Copyright © 2019 Steve Algernon. All rights reserved.
//

import Foundation

public class StderrOutputStream: TextOutputStream {
	public func write(_ string: String) {
		fputs(string, stderr)
	}
}

public var errStream = StderrOutputStream()

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

enum ReaderError : Error {
	case unexepectedEOF(_ missing:String);
	case fatalError(_ msg:String);
	case badForm(_ r:Reader);
	case oddHashElements(elems:[MalType]);
	case emptyLine;
	case undefinedSymbol(_ s:MalType);
}

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

	class func verbose(_ s: String) -> Void {
		let x = getenv("MALVERBOSE");
		if (x != nil) {
			print("#\n# " + s + "\n#\n", to: &errStream);
		}
	}

	class func read_str(_ s: String) throws -> MalType {
		let t = tokenize(s);

		if (t.count == 0) {
			throw ReaderError.emptyLine;
		}

		let r = Reader(t);

		let f = try read_form(r);

		verbose("Parsed out as: \(f)");

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


	class func read_form(_ r: Reader) throws -> MalType {
		let l = r.peek();
		guard (l != nil) else {
			throw ReaderError.badForm(r);
		}

		let opening = l!._string;

		let kinds : [MalCollection.Type] = [ MalList.self, MalVector.self, MalHash.self ];

		for k in kinds {
			let d = k.delims();
			if (d[0] == opening) {
				return try read_list(r, kind:k);
			}
		}

		return read_atom(r);
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

	class func read_list(_ r: Reader, kind:MalCollection.Type) throws -> MalType {
		var l : [MalType] = [];
		let eol = kind.delims()[1];

		_ = r.next();

		while (true) {
			let t = r.peek();

			guard t != nil else {
				throw ReaderError.unexepectedEOF("missing \(eol)");
			}

			if (t!._string == eol) {
				_ = r.next();
				break;
			}


			let v = try read_form(r);
			l.append(v);
		}

		return try! kind.init(l);
	}

	class func read_atom(_ r: Reader) -> MalType {
		let s = r.next()._string;

		let l = (s as NSString).length;
		if (l >= 2) {
			let ch = (s as NSString).substring(to: 1);
			if (ch == "\"") {
				let ch2 = (s as NSString).substring(from: l - 1);
				if (ch2 != "\"") {
					print("Atom EOF");
					return MalNil();
				}
			}
		}

		verbose("read atom: " + s);

		switch (s) {
		case "'":
			return MalQuote();
		case "`":
			return MalQuasiQuote();
		case MalNil.canonicalString:
			return MalNil();
		case MalTrue.canonicalString:
			return MalTrue();
		case MalFalse.canonicalString:
			return MalFalse();
		default:
			if (s.hasPrefix(":")) {
				let after = s.index(after:s.startIndex);
				let remainder = s[after...];
				return MalKeyword(String(remainder));
			} else {
				let cvt = (s as NSString).integerValue;
				if (s.compare("\(cvt)") == ComparisonResult.orderedSame) {
					return MalScalar(cvt);
				} else {
					return MalString(s);
				}
			}
		}
	}

	class func tokenize(_ s: String) -> [Token] {
		//		let str = "[\\s,]*(~@|[\\[\\]{}()'`~^@]|\"(?:\\\\.|[^\\\\\"])*\"?|;.*|[^\\s\\[\\]{}('\"`,;)]*)";

		let or = "|";

		let str = "[\\s,]*"
		+ "("
			+ "~@"
			+ or
			+ "[\\[\\]{}()'`~^@]"
			+ or
			+ "\""
				+ "("
					+ "?:\\\\."
					+ "|"
					+ "[^\\\\\"]"
				+ ")*"
			+ "\"?"
			+ or
			+ ";.*"
			+ or
			+ "[^\\s\\[\\]{}('\"`,;)]*"
		+ ")";

		let n = try! NSRegularExpression.init(pattern: str, options: []);
		let matches = n.matches(in: s, options: [], range: NSRange(location:0, length:s.count));

		var tokens : [Token] = [];

		for m in matches {
			let ss = (s as NSString).substring(with: m.range);
//			let sa = ss.trimmingCharacters(in: CharacterSet.whitespaces);
			let st = ss.trimmingCharacters(in: CharacterSet.init(charactersIn: ", \t\n\r"));

			if (st.count > 0 && st[st.startIndex] != ";") {
				verbose("MATCH>>>\(st)<<<");
				tokens.append(Token.parse(st));
			}
		}

		return tokens;
	}
};
