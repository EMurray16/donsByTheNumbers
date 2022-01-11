package rsexp

import (
	"errors"
)

// These constants are enumerations of the SEXPTYPEs that are part of R's internals. There are about 2 dozen in all,
// the rsexp package only supports 5 of them.
const (
	CHARSXP = 9
	INTSXP  = 13
	REALSXP = 14

	// A STRSXP is actually a vector of strings, where each element points to a CHARSXP.
	STRSXP = 16

	// It's not obvious from the name, but a VECSXP is a list. Each element of a
	// VECSXP is a SEXP and can be of any type.
	VECSXP = 19
)

// RCharacter is a type parameter of Go types that map well onto R's character type, which is a string and a byte slice.
type RCharacter interface {
	~string | ~[]byte
}

// RNumeric is a type parameter of Go types that map well onto R's numberic types, including both doubles and integers.
// It includes both float types and all int types. It does not contain unsigned integers because R has no equivalent
// type.
type RNumeric interface {
	~float64 | ~float32 |
	~int | ~int8 | ~int16 | ~int32 | ~int64
}

// TypeMismatch is most often returned from an AsX method when the caller tries to extract the incorrect type from
// a SEXP.
var TypeMismatch = errors.New("input SEXP type does not match desired output type")

// NotASEXP is returned by NewGoSEXP when it cannot coerce the input object into a *C.SEXP.
var NotASEXP = errors.New("non-SEXP object provided to a function that needs a SEXP")

// Any Matrix function or method which can return an error will first check the input Matrix or matrices for
// validity and return an ImpossibleMatrix error if there is an inconsistency between the matrix data and
// dimensions.
var ImpossibleMatrix = errors.New("matrix size and underlying data length are not compatible")

// All matrix and data.frame operations check inputs for validity and will return errors where applicable.
var (
	SizeMismatch     = errors.New("operation is not possible with given input dimensions")
	InvalidIndex     = errors.New("given index is impossible (ie < 0)")
	IndexOutOfBounds = errors.New("index is out of bounds (ie too large)")
	LengthMismatch = errors.New("lengths of provided inputs are not the same")
)

// Matrix is a representation of a matrix in Go that mirrors how matrices are represented in R. The Matrix
// contains a vector of all the data, and a header of two integers that contain the dimensions of the matrix.
// The Data vector is organized so that column indices are together, but row indices are not. In other words, the
// data can be thought of as a concatenation of several vectors, each of which contains the data for one column.
//
// For example, the following Matrix:
//     Matrix{Nrow: 3, Ncol: 2, Data: []float64{1.1,2.2,3.3,4.4,5.5,6.6}}
// will look like this:
//    [1.1, 4.4
//     2.2, 5.5
//     3.3, 6.6]
//
// Matrix data is accessed using 0-based indexing, which is natural in Go but differs from R. For example, the 0th
// row in the example matrix is [1.1, 4.4], while the "1st" row is [2.2, 5.5].
type Matrix struct {
	// The Matrix header - two integers which specify its dimension
	Nrow, Ncol int

	// The data in a matrix is represented as a single slice of data
	Data []float64
}

// isSizeValid checks to make sure a matrix's dimensions and data length match.
func (m *Matrix) isSizeValid() bool {
	return m.Nrow*m.Ncol == len(m.Data)
}