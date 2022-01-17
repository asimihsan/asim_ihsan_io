// http://alloy4fun.inesctec.pt/xM8cQRXSSBoXBYsyB

/* 
  A bounded buffer can be implemented by a circuar array of cells,
  each containing a value. At each moment two variables, read and write, are used
  to point to the cells where the next value should be read or written, respectively.
*/

sig Value {}

sig Cell {
	succ : one Cell,
	var content : lone Value
}

var one sig read, write in Cell {}

pred circular {
	// The cells are structured in a single ring, with succ pointing to the next cell

}


pred send [v : Value] {
	// Send value v to the buffer

}


pred receive [v : Value] {
	// Receive value v from the buffer
  
}


pred prop1 {
	// In the first state the buffer is empty

}


pred prop2 {
	// Every received value was previously sent

}


pred prop3 {
	// If writes become impossible, the next write can only happen after a receive

}


pred weak_fairness {
	// If receive is permanently enabled then it must eventually occur

}


pred prop4 {
	// If the system is weekly fair for receive, every sent value will be received

}
