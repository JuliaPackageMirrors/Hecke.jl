add_verbose_scope(:NfMaxOrd)
add_assert_scope(:NfMaxOrd)

#set_verbose_level(:NfMaxOrd, 1)

include("NfMaxOrd/NfMaxOrd.jl")
include("NfMaxOrd/Ideal.jl")
include("NfMaxOrd/Zeta.jl")
include("NfMaxOrd/FracIdeal.jl")
include("NfMaxOrd/Clgp.jl")
include("NfMaxOrd/Unit.jl")
include("NfMaxOrd/ResidueField.jl")
include("NfMaxOrd/ResidueRing.jl")
include("NfMaxOrd/FactorBaseBound.jl")
include("NfMaxOrd/FacElem.jl")
include("NfMaxOrd/LinearAlgebra.jl")