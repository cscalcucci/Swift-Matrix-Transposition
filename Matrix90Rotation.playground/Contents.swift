//: Playground - noun: a place where people can play

import UIKit

public enum Rotation : Int {
    case n0     = 0
    case n90    = 90
    case n180   = 180
    case n270   = 270
    
    func shouldInvert() -> Bool {
        switch self {
        case .n0, .n180     : return false
        default             : return true
        }
    }
}

// Reusable Matrix class from an old project - Hope you don't mind that I used this instead of a standard multi-dimensional Array<Array <Int>>
public class Matrix<T> {
    private typealias Transposition = (x: Int, y: Int) -> Int

    public let width: Int
    public let height: Int
    private var dimensions : (width: Int, height: Int) {
        get {
            return self.rotation.shouldInvert() ?
                (self.height, self.width) : (self.width, self.height)
        }
    }
    private var elements: [T]
    private(set) public var rotation = Rotation.n0
    
    // Init for generating a Matrix without initial elements, repeatedValue T allows for population
    public init(width: Int, height: Int, repeatedValue: T) {
        // Check for nil
        assert(width >= 0,  "Matrix<T> critical error, Matrix.width  >= 0")
        assert(height >= 0, "Matrix<T> critical error, Matrix.height >= 0")
        
        self.width = width
        self.height = height
        elements = Array<T>(count: width*height, repeatedValue: repeatedValue)
    }
    
    // Init for generating a Matrix with an initial array of elements
        // If array is inadequate (out of index range), the Matrix populates any empty indexes with 0 and warns the user
    public init(width: Int, height: Int,inout elements: [T]) {
        //Check for nil
        assert(width  >= 0, "Matrix<T> critical error, Matrix.width  >= 0")
        assert(height >= 0, "Matrix<T> critical error, Matrix.height >= 0")
        
        let difference = (elements.count - (width * height))
        
        // To allow input of elements where elements is smaller than the desired size of the Matrix, we calculate the difference and append 0s to fill in the empty spots
        // Print whenever this happens so that the user knows their input data was not adequate, but can be used with inaccuracy by the 0s. 
        //This will be problematic, and in real production an assertion should be made to ensure the input elements, [T], is the same size as Width * Height
        if difference != 0 {
            for _ in 0..<difference {
                elements.append(0 as! T)
                print("Appending 0 to input [T] to satisfy Width/Height requirements")
            }
        }
        
        self.width = width
        self.height = height
        self.elements = Array<T>(elements)
    }
    
    // Rotation property is a public get only, and set internally through this fn
    public func rotate(degrees: Rotation) {
        self.rotation = degrees
    }
    
    /// Gets an element in the matrix using it's x and y position after applying a transposition-lookup algorithm generated based on self.rotation
    public subscript(x: Int, y: Int) -> T {
        get {

            assert(x >= 0 && x < self.dimensions.width,  "Matrix<T> critical error, X >= 0 && X < Matrix.width")
            assert(y >= 0 && y < self.dimensions.height, "Matrix<T> critical error, X >= 0 && X < Matrix.height")
            
            return elements[transpose(x, y, rotation: self.rotation)]
        }
        set(newValue) {
            assert(x >= 0 && x < self.dimensions.width,  "Matrix<T> critical error, X >= 0 && X < Matrix.width")
            assert(y >= 0 && y < self.dimensions.height, "Matrix<T> critical error, X >= 0 && X < Matrix.height")
            
            elements[transpose(x, y, rotation: self.rotation)] = newValue
        }
    }
    
    // Allows for random generation of elements using an elementGeneration input, which is any fn that returns a generic type
    public func generatePopulation(elementGenerator: () -> T?) {
        for x in 0..<width {
            for y in 0..<height {
                if let value = elementGenerator() {
                    self[x,y] = value
                }
            }
        }
    }
    
    // Derives a transposition algorithm based on (x,y) input from the subscript that gets run against current rotational state. Note that .n180 and .n270 are NOT implemented
    private func transpose(x: Int, _ y: Int, rotation: Rotation) -> Int {
        func getFn(rotation: Rotation) -> Transposition {
            switch rotation {
            case .n0:
                // Algorithm: e[x + (y * w)]
                return { x,y in x + (y * self.width) }
            case .n90:
                // Algorithm: e[(w - (h - (y - 1))) + ((h - (w - (x - 1))) * w)]
                return { x,y in ((self.width - (self.height - (y - 1))) + ((self.height - (self.width - (x - 1))) * self.width)) }
            case .n180:
                // Algorithm not implemented yet, default with a print warning
                print("Warning: algorithm n180 not implemented, defaulting to n0 rotation lookup")
                return { x,y in x + (y * self.width) }
            case .n270:
                // Algorithm not implemented yet, default with a print warning
                print("Warning: algorithm n270 not implemented, defaulting to n0 rotation lookup")
                return { x,y in x + (y * self.width) }
            }
        }
        
        func mapFn(x: Int,_ y: Int, fn: Transposition) -> Int {
            return fn(x: x, y: y)
        }
        
        return mapFn(x, y, fn: getFn(rotation))
    }
    
    // Construct a nested, multidimensional array at O(n)
        // Didn't have enough time to debug this, but it's extraneous anyways - just subscript (x,y) coords after setting rotation
    public func constructMatrix() -> Array<Array <T>> {
        var arr = Array<Array <T>>()
        for x in 0..<self.width {
            for y in 0..<self.height {
                arr[x][y] = self[x, y]
            }
        }
        
        return arr
    }
    
    // Strapped for time, so this isn't optimized at all, and just bootstraps onto the back of constructMatrix()
        // Didn't have enough time to debug this, but it's extraneous anyways - just subscript (x,y) coords after setting rotation
    public func printMatrix() {
        let arr = constructMatrix()
        for y in 0..<arr.count {
            print(arr[y])
        }
    }
}

extension Matrix: SequenceType {
    public func generate() -> MatrixGenerator<T> {
        return MatrixGenerator(matrix: self)
    }
}

// Generator to allow the matrix to move through it's elements like a real sequence
    // Note to self: Add more stepping fn() later for increased use-cases
public class MatrixGenerator<T>: GeneratorType {
    
    private let matrix: Matrix<T>
    private var x = 0
    private var y = 0
    
    init(matrix: Matrix<T>) {
        self.matrix = matrix
    }
    
    public func next() -> (x: Int, y: Int, element: T)? {
        // Check for nil
        if self.x >= matrix.width { return nil }
        if self.y >= matrix.height { return nil }
        
        // Extract the element and increase the counters
        let returnValue = (x, y, matrix[x, y])
        
        // Increase the counters
        ++x; if x >= matrix.width { x = 0; ++y }
        
        return returnValue
    }
}

// MATRIX TRANSPOSITION (nXm)

//                                  8   4   0
// 0   1   2   3
//                                  9   5   1
// 4   5   6   7    ---(n90)--->
//                                  10  6   2
// 8   9  10  11
//                                  11  7   3


// Create a flat array of elements equal to the size of your desired matrix
    // Note: I created an overloaded init() to accept repeatedValues or an array like this
        // Ideally the array could be any size and init would compensate by filling in empty spaces, but I didn't have enough time to debug it.
var e = [0,1,2,3,4,5,6,7,8,9,10,11,12]

// Create the matrix using a flat array and supplying height and width
    // This matrix is stateless - the initial elements NEVER change their arrangement, nor do they mutate
let matrix = Matrix(width: 4, height: 3, elements: &e)

// Accessing any coordinate of the matrix with our subscript with apply an algorithm to determine the element that would be there
    // It only appears as though these elements are stored at that coordinate. In reality, the elements always exist in a flat array, and dimensions are simulated with runtime algorithms
print(matrix[3,0])

// Apply rotation to the matrix. By setting this, you are changing which lookup algorithm is used in the subscript, where each fn accounts for nDegree rotation
    // Note: Real rotation never actually happens - which how we maintain statelessness. The rotatation is really just an abstraction of our lookup algorithm
matrix.rotate(.n90)

// matrix[3,0] which accesses element '3' becomes matrix[2,3] after applying rotation. This print is a proof that the matrix is capable of simulating rotation without actually changing the element array
print(matrix[2,3])


