// https://www.hillelwayne.com/post/nix/

// TODO
// - Simplify signatures?
// - Write a naive package manager that only allows one version
//   of a package to exist, show it doesn't work.
// - Just do install of anything without dependency resolution, show
//   that is doesn't work.

open util/ordering[Version]

sig Package {
	name : one Name,
	version : one Version,
	requires : set Package,
//	upgrade : lone Package,
}

var sig InstalledPackage in Package {}

sig Name {}

sig Version {}

fact {
	// A Package appears zero or one times as an upgrade
//	upgrade in Package lone -> Package

	//	A Package can't require its own upgrade.
//	all p : Package | no (p.requires & p.requires.^upgrade)

	// A Package can't upgrade to itself
//	all p : Package | no (p & p.upgrade)

	// No orphan versions
	all v : Version | some (Package.version & v)

	// No orphan names
	all n : Name | some (Package.name & n)
	
	// Package can't require itself (by name)
	all p : Package | no (p.name & p.requires.name)
}

// Since this constraint has no temporal operators, it only applies to the
// initial state of the system.
fact {
	no InstalledPackage
}

enum Event { Stutter, Install }

pred install[p : Package] {
	// guard
	p not in InstalledPackage

	// effect on installed
//	p.name not in InstalledPackage.name implies InstalledPackage' = InstalledPackage + p
//										else    InstalledPackage' = InstalledPackage
//
//	all p2 : p.requires | install[p2]

	InstalledPackage' = InstalledPackage + p.*requires

	// no frame conditions
}

fun install_happens : set Event -> Package {
	{ e : Install, p: Package | install[p] }
}

pred stutter {
	// no guard
	// no effects
	InstalledPackage' = InstalledPackage	// frame condition
}

fun stutter_happens : set Event {
	{ e : Stutter | stutter }
}

fact {
	always (
		stutter or
		some p : Package | install[p]
	)
}

assert PackagesHaveDependencies {
	always (all p : Package | p in InstalledPackage implies p.*requires in InstalledPackage)
}

check PackagesHaveDependencies for 5


run example {
	// Want a trace with some package in it, avoid trivial package manager.
	some Package

	// Packages should require something. This should be removed for proofs
	// but for exploration we want something non-trivial.
	some Package.requires

	// Just to make interesting examples.
	// #(Package.name) <= 2

	// Packages should upgrade to something. Again remove for proofs
	// but for exploration useful.
//	some Package.upgrade
} for 5
