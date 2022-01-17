sig Node {
	edge : set Node
}

// One distinguised Node called Root is special.
// Use 'in' because Root is not disjoint with Node.
// Use 'lone' to say there is always 0 or 1 Root.
lone sig Root in Node {}

fact {
	// No cycles
	no n : Node | n in n.^edge

	// All Nodes except Root must appear in an edge
	all n : Node - Root | one (n & Node.edge)

	// Nothing can point to Root
	no (Root & Node.edge)

	// Every node is pointed to by one edge
	edge in Node lone -> Node
}

pred binary_tree[n : Node] {
	#n.edge <= 2
	all child : n.edge | binary_tree[child]
}

run {
	some n : Node | binary_tree[n]
} for 10 but 5 Node
