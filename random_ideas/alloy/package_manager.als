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

	// Package can only require one version of a named package
	all p1 : Package, disj p2, p3 : p1.*requires | p2.name != p3.name
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
//									x	else    InstalledPackage' = InstalledPackage
//
//	all p2 : p.requires | install[p2]

	// This enforces only one package with same name installed at any given time
	InstalledPackage' = p.*requires + {p2 : InstalledPackage | p2.name not in (p.*requires).name}

	// This allows multiple names installed.
	// InstalledPackage' = p.*requires + InstalledPackage

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
		one p : Package - InstalledPackage | install[p]
	)
}

assert PackagesHaveDependencies {
	always (all p : InstalledPackage | p.*requires in InstalledPackage)
}

check PackagesHaveDependencies for 3


run example {
	// Want a trace with some package in it, avoid trivial package manager.
	some Package

	// Packages should require something. This should be removed for proofs
	// but for exploration we want something non-trivial.
	some Package.requires

	// Just to make interesting examples.
	#(Package.name) <= 2

	// Getting some interesting examples, requirements in common
	some disj p1, p2 : Package | some(p1.^requires & p2.^requires)

	// Packages should upgrade to something. Again remove for proofs
	// but for exploration useful.
//	some Package.upgrade
} for 3
