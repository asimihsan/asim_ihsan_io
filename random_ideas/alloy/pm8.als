sig Package {
    name : one Name,
    version : one Version,
    requires : set Package,
}

var sig InstalledPackage in Package {}

sig Name {}

sig Version {}

fact "only one package version in dependency graph for package" {
	all p1 : Package, disj p2, p3 : p1.*requires | p2.name != p3.name
}

fact "package doesn't require itself at any version" {
	all p : Package | p.name not in (p.requires).name
}

fact {
	no InstalledPackage
}

enum Event { Stutter, Install }

fun install_happens : set Event -> Package {
	{ e : Install, p: Package | install[p] }
}

fun stutter_happens : set Event {
	{ e : Stutter | stutter }
}

pred install[p : Package] {
	// guard
	p not in InstalledPackage

	// effects

	// This enforces only one package with same name installed at any given time
	InstalledPackage' = p.*requires + {p2 : InstalledPackage | p2.name not in (p.*requires).name}

	// no frame conditions
}

pred stutter {
	// no guard
	// no effects
	InstalledPackage' = InstalledPackage	// frame condition
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
	// At least 3 Packages
	#(Package.name) >= 3

	// At least two requirements
	#(Package.requires) >= 2
} for 5
