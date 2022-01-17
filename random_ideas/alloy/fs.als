abstract sig Object {}
sig File extends Object {}
sig Dir extends Object {
	entries : set Entry
}
sig Entry {
	name : one Name,
	object : one Object
}
sig Name {}

one sig Root extends Dir {}

fact {
	// Entries cannot be shared between directories

	// Force relation 'entries' to be injective, one where no two
	// atoms of the source signature point to the same target atoms.
	// Note "a bestiary of binary relations" seems important.
	//entries in Dir lone -> Entry

	// entries.e is the set of all directories that contain e as an entry
    // all e : Entry | lone entries.e

	// all disj x, y : Dir | no (x.entries & y.entries)

	// all x,y : Dir | x != y implies no (x.entries & y.entries)
}

fact {
	// this is the second part, strengthening it, prevent orphan entries not in
	// directories
	entries in Dir one -> Entry
}

fact {
	// Different entries in the same directory must have different names


	// name.n goes to the parent of the Name relation
	// lone is at most one
	all d : Dir, n : Name | lone (d.entries & name.n)

	// all d : Dir, disj x, y : d.entries | x.name != y.name
}

fact {
	// A directory cannot be contained in more than one entry
	all d : Dir | lone object.d

	// This is wrong because it forces relation object to only
	// relate entries to directories (excluding files)
	// object in Entry lone -> Dir
}

fact {
	// Every object except the root is contained somewhere
	Entry.object = Object - Root
}

fact {
	// Directories cannot contain themselves: direct
	all d : Dir | d not in d.entries.object
 
	// Directories cannot contain themselves directly or indirectly
	all d : Dir  | d not in d.^(entries.object)
}

assert no_partitions {
	// Every object is reachable from the root
	Object - Root = Root.^(entries.object)
}

check no_partitions

run example {
	some File
	some Dir - Root
} for 5

// At the point where it says "but we still have two issues",
// I wanted to see an example of directories contained in themselvrs
run example2 {
	some d: Dir - Root | some (d.entries.object & d)
} for 5
