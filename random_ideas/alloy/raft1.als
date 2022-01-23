// https://github.com/AlloyTools/org.alloytools.alloy/blob/master/org.alloytools.alloy.extra/extra/models/examples/algorithms/messaging.als

abstract sig Message {
	from: one Node,
	to: one Node,
}

sig RequestVoteSendMessage extends Message {}
sig RequestVoteResponseMessage extends Message {}

enum NodeState { Follower, Candidate, Leader }

sig Node {
	var state : one NodeState,
	var inbox : set Message,
	var outbox: set Message
}

fact {
	Node.state = Follower
	no Node.inbox
	no Node.outbox
	no Message
}

pred stutter {
	// no guard
	// no effect
	// frame conditions
	Node.state' = Node.state
	Node.inbox' = Node.inbox
	Node.outbox' = Node.outbox
}

pred become_candidate[n : Node] {
	// guard
	n.state = Follower

	// effect
	n.state' = Candidate

	// frame condition
	all n2 : Node - n | n2.state' = n2.state
	Node.inbox' = Node.inbox
	Node.outbox' = Node.outbox
}

enum Event { Stutter, BecomeCandidate }

fun become_candidate_happens : set Event -> Node {
	{ e : BecomeCandidate, n: Node | become_candidate[n] }
}

fun stutter_happens : set Event {
	{ e : Stutter | stutter }
}

// run loop
fact {
	always (
		stutter or
		some n : Node | become_candidate[n]
	)
}

run example {
	#(Node) >= 3
	#(Node) <= 5
} for 10
