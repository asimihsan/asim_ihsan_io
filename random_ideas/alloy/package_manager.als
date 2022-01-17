// https://www.hillelwayne.com/post/nix/

// TODO
// - Simplify signatures?
// - Write a naive package manager that only allows one version
//   of a package to exist, show it doesn't work.
// - Just do install of anything without dependency resolution, show
//   that is doesn't work.

open util/ordering[Version]

sig Package {
	version : one Version,
	requires : set Package,
	upgrade : lone Package,
}

sig Version {}

fact {
	// A Package appears zero or one times as an upgrade
	upgrade in Package lone -> Package

	//	A Package can't require its own upgrade.
	all p : Package | no (p.requires & p.requires.^upgrade)

	// A Package can't upgrade to itself
	all p : Package | no (p & p.upgrade)

	// No orphan versions
	all v : Version | some (Package.version & v)
	
	// Package can't require itself
	all p : Package | no (p & p.requires)
}

one sig System {
	var installed : set Package
}

// Since this constraint has no temporal operators, it only applies to the
// initial state of the system.
fact {
	no System.installed
}

enum Event { Stutter, Install }

pred install[s : System, p : Package] {
	p not in s.installed				// guard
	s.installed' = s.installed + p		// effect on installed
	// no frame conditions
}

fun install_happens : Event -> System -> Package {
	{ e : Install, s: System, p: Package | install[s, p] }
}

pred stutter[s : System] {
	// no guard
	// no effects
	s.installed' = s.installed			// frame condition
}

fun stutter_happens : Event -> System {
	{ e : Stutter, s: System | stutter[s] }
}

fact {
	always (some s : System, p : Package |
		stutter[s] or
		install[s, p]
	)
}

run example {
	// Want a trace with some package in it, avoid trivial package manager.
	some Package

	// Packages should require something. This should be removed for proofs
	// but for exploration we want something non-trivial.
	some Package.requires

	// Packages should upgrade to something. Again remove for proofs
	// but for exploration useful.
	some Package.upgrade
} for 3
