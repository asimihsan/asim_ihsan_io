class Node
{
    // a single field giving the nods linked to
    var next: seq<Node>
}

// nodes only point to other nodes in the graph, and not to itself.
predicate closed(graph: set<Node>)
    reads graph
{
    //null !in graph && // graphs can only consist of actual nodes,  not null. Dafny infers this.
    forall i :: i in graph ==>
        forall k :: 0 <= k < |i.next| ==> i.next[k] in graph && i.next[k] != i
}

predicate pathSpecific(p: seq<Node>, start: Node, end: Node, graph: set<Node>)
    requires closed(graph)
    reads graph
{
    |p| > 0 && // path is non-empty
    p[0] == start && p[|p|-1] == end && // it starts and ends correctly
    path(p, graph) // and it is a valid path
}

predicate path(p: seq<Node>, graph: set<Node>)
    requires closed(graph)
    requires |p| > 0
    reads graph
{
    p[0] in graph &&
    (|p| > 1 ==> p[1] in p[0].next && // the first link is valid, if it exists
        path(p[1..], graph)) // and the rest of the sequence is valid
}

lemma ClosedLemma(subgraph: set<Node>, root: Node, goal: Node, graph: set<Node>)
    requires closed(subgraph)
    requires closed(graph)
    requires subgraph <= graph
    requires root in subgraph
    requires goal in graph - subgraph
    ensures !(exists p: seq<Node> :: pathSpecific(p, root, goal, graph))
{
    forall p {
        DisproofLemma(p, subgraph, root, goal, graph);
    }
}

lemma DisproofLemma(p: seq<Node>, subgraph: set<Node>, root: Node, goal: Node, graph: set<Node>)
    requires closed(subgraph)
    requires closed(graph)
    requires subgraph <= graph
    requires root in subgraph
    requires goal in graph - subgraph
    ensures !pathSpecific(p, root, goal, graph)
{
    if |p| > 1 && p[0] == root && p[|p|-1] == goal {
        if p[1] in p[0].next {
            DisproofLemma(p[1..], subgraph, p[1], goal, graph);
        }
    }
}