_build/install/default/bin/coqc watest.v 2> >(sed -e "s/Ind(Coq.Init.Datatypes.nat,0)/nat/g" -e "s/Ind(Coq.Vectors.Vector.t,0)/Vect.t/g") 
