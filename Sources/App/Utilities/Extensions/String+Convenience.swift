//
//  Created by Carlo Rapisarda 2022.
//  Copyright © 2022 Carlo Rapisarda. All rights reserved.
//

import Foundation

func /(lhs: String, rhs: String) -> String {
    (lhs as NSString).appendingPathComponent(rhs)
}
