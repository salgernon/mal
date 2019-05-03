//
//  Printer.swift
//  smux
//
//  Created by steve algernon on 5/3/19.
//  Copyright © 2019 Steve Algernon. All rights reserved.
//

import Foundation

class Printer {
	class func pr_str(_ m: MalType) {
		let s = m.toString();
		print("\(s)");
	}
};
