sig Package {
    name : one Name,
    version : one Version,
    requires : set Package,
}

sig Name {}

sig Version {}

fact "only one package version in dependency graph for package" {
	all p1 : Package, disj p2, p3 : p1.*requires | p2.name != p3.name
}

run example {}
