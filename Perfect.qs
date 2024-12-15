// Q# program implementing a quantum error correction (QEC) code for 5 qubits.
// The program encodes a logical qubit, introduces random errors, detects errors using syndromes,
// and corrects the detected errors before decoding the logical qubit back to its original state.

@Config(Unrestricted)
import Std.Diagnostics.CheckAllZero; // Checks if all qubits are in the |0⟩ state.
import Std.Random.DrawRandomInt; // Generates a random integer within a specified range.
import Std.Convert.ResultArrayAsInt; // Converts a Result array (syndrome measurements) into an integer.
import Std.Diagnostics.DumpMachine; // Dumps the quantum state for debugging.

// Used "Quantum Circuits for Stablizer Error Correcting Codes: A Tutorial" by Mondal and Parhi 
// as reference.
@Config(Unrestricted)
operation Main() : Unit {
    use logicalQubit = Qubit[5]; // Allocates 5 physical qubits for the logical qubit.

    Encode(logicalQubit); // Encodes the logical qubit using the 5-qubit code.

    ApplyError(logicalQubit); // Introduces a random error on one of the qubits.

    let index = Detect(logicalQubit); // Detects the error using syndrome measurements.
    if (index != 0) { // If an error is detected:
        Message("Error Detected");
        Correct(index, logicalQubit); // Corrects the detected error.
    } else {
        Message("No Error Detected");
    }

    Decode(logicalQubit); // Decodes the logical qubit back to its original state.

    ResetAll(logicalQubit); // Resets all qubits to the |0⟩ state.
}

// Implements the encoding circuit for the 5-qubit code, following the reference paper.
// From Fig. 10, Page 9
operation Encode(qs : Qubit[]) : Unit is Adj {
    H(qs[0]); // Hadamard on qubit 0.
    S(qs[0]); // S gate on qubit 0.
    CY(qs[0], qs[4]); // Controlled-Y gate between qubits 0 and 4.
    H(qs[1]); // Hadamard on qubit 1.
    CNOT(qs[1], qs[4]); // Controlled-NOT between qubits 1 and 4.
    H(qs[2]);
    CZ(qs[2], qs[0]);
    CZ(qs[2], qs[1]);
    CNOT(qs[2], qs[4]);
    H(qs[3]);
    S(qs[3]);
    CZ(qs[3], qs[0]);
    CZ(qs[3], qs[2]);
    CY(qs[3], qs[4]);
}

// Decodes the logical qubit by applying the adjoint of the encoding circuit.
operation Decode(qs: Qubit[]) : Unit {
    Adjoint Encode(qs);
}

// Measures the syndrome values for error detection using the stabilizer generators.
operation Detect(qs: Qubit[]) : Int {
    let syndrome1 = Measure([PauliX,PauliZ, PauliZ, PauliX, PauliI], qs);
    let syndrome2 = Measure([PauliI,PauliX, PauliZ, PauliZ, PauliX], qs);
    let syndrome3 = Measure([PauliX,PauliI, PauliX, PauliZ, PauliZ], qs);
    let syndrome4 = Measure([PauliZ,PauliX, PauliI, PauliX, PauliZ], qs);

    Message($"Value of Syndromes in order {syndrome1}, {syndrome2}, {syndrome3}, {syndrome4}");
    let decimalValue = ResultArrayAsInt([syndrome4, syndrome3, syndrome2, syndrome1]);
    Message($"Decimal Value of Syndrome Measurement is {decimalValue}");
    return decimalValue;
}

// Corrects the error on the affected qubit based on the detected syndrome value.
// Maps syndrome values (integer) to error type and affected qubit.
// This uses a lookup table in the paper.
operation Correct(i : Int, qs : Qubit[]) : Unit {
    if (i == 1){
        Message("Bit Flip Error on Qubit 0 detected and corrected.");
        X(qs[0]);
    }
    elif (i == 10){
        Message("Z Error on Qubit 0 detected and corrected.");
        Z(qs[0]);
    }
    elif (i == 11){
        Message("Y Error on Qubit 0 detected and corrected.");
        Y(qs[0]);
    }
    elif (i == 8){
        Message("Bit Flip Error on Qubit 1 detected and corrected.");
        X(qs[1]);
    }
    elif (i == 5){
        Message("Z Error on Qubit 1 detected and corrected.");
        Z(qs[1]);
    }
    elif (i == 13){
        Message("Y Error on Qubit 1 detected and corrected.");
        Y(qs[1]);
    }
    elif (i == 12){
        Message("Bit Flip Error on Qubit 2 detected and corrected.");
        X(qs[2]);
    }
    elif (i == 2){
        Message("Z Error on Qubit 2 detected and corrected.");
        Z(qs[2]);
    }
    elif (i == 14){
        Message("Y Error on Qubit 2 detected and corrected.");
        Y(qs[2]);
    }
    elif (i == 6){
        Message("Bit Flip Error on Qubit 3 detected and corrected.");
        X(qs[3]);
    }
    elif (i == 9){
        Message("Z Error on Qubit 3 detected and corrected.");
        Z(qs[3]);
    }
    elif (i == 15){
        Message("Y Error on Qubit 3 detected and corrected.");
        Y(qs[3]);
    }
    elif (i == 3){
        Message("Bit Flip Error on Qubit 4 detected and corrected.");
        X(qs[4]);
    }
    elif (i == 4){
        Message("Z Error on Qubit 4 detected and corrected.");
        Z(qs[4]);
    }
    elif (i == 7){
        Message("Y Error on Qubit 4 detected and corrected.");
        Y(qs[4]);
    }
    else{
        Message("Index out of range (1-15)");
    }
}

// Introduces a random error (bit flip, phase flip, or Y error) on a randomly selected qubit.
operation ApplyError(qs: Qubit[]) : Unit {
    let index = DrawRandomInt(0,4); // Randomly selects one of the 5 qubits.
    let error = DrawRandomInt(0,2); // Randomly selects the type of error: X (0), Z (1), or Y (2).
    if (error == 0) {
        Message($"Applying Bit Flip Error on Qubit {index}");
        X(qs[index]); // Applies an X (bit-flip) error to the selected qubit.
    } elif (error == 1) {
        Message($"Applying Phase Flip Error on Qubit {index}");
        Z(qs[index]); // Applies a Z (phase-flip) error to the selected qubit.
    } else {
        Message($"Applying Y Error on Qubit {index}");
        Y(qs[index]); // Applies a Y error (bit + phase flip) to the selected qubit.
    }
}

// A logical X operation that applies an X gate to all qubits in the array.
operation LogicalX(qs: Qubit[]) : Unit {
    ApplyToEach(X, qs);
}

// A logical Z operation that applies a Z gate to all qubits in the array.
operation LogicalZ(qs: Qubit[]) : Unit {
    ApplyToEach(Z, qs);
}