sig Node {
    edge: set Node
} {
	// this not in edge
}

pred has_self_loop {
	some n : Node | n in n.edge
    // some e: edge | e = ~e
}

assert no_loops {
	no n : Node | n in n.^edge
}

check no_loops

run {
    has_self_loop
}
