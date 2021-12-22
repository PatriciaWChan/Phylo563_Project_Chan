#example plotting a tree from text
myTree <- ape::read.tree(text='((A, B), ((C, D), (E, F)));')
plot(myTree)

#write parenthetical tree with topology yielded by nuclear ML tree- use letters as stand-ins for OTUs
unnamed_tree <- ape::read.tree(text='(((((((A, B), C), D), E), (((F, G), (H, I)), J)), K), (L,M));')
plot(unnamed_tree, direction= "leftwards")

#sub in species names for letters as OTUs
nuclear_Darwiniatree <- ape::read.tree(text='(((((((Darwinia_polycephala, Darwinia_sp._Gibson), Darwinia_sp._Mt._Ragged), Darwinia_masonii), Darwinia_oldfieldi), ((Darwinia_meeboldii, Darwinia_collinia), (Darwinia_citriodora, Darwinia_ferricola), Darwinia_virescens)), Darwinia_sp._Dryandra), (Verticordia_helichrysantha, Verticordia_cooloomia));')
plot(nuclear_Darwiniatree, direction= "leftwards")

#fabricate a tree to demonstrate hypothetical data. change some topology from nuclear tree
fab_plastome_Darwiniatree <- ape::read.tree(text='(((((((Darwinia_polycephala, Darwinia_sp._Gibson), Darwinia_sp._Mt._Ragged), Darwinia_oldfieldi), Darwinia_masonii), (((Darwinia_meeboldii, Darwinia_collinia), (Darwinia_citriodora, Darwinia_ferricola)), Darwinia_virescens), Darwinia_sp._Dryandra)), (Verticordia_helichrysantha, Verticordia_cooloomia));')
plot(fab_plastome_Darwiniatree, direction= "leftwards")
#created a polytomy and slightly altered topology
#will manually assign hypothetical "bootstrap values"