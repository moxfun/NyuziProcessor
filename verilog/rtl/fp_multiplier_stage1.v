module fp_multiplier_stage1
	#(parameter EXPONENT_WIDTH = 8, 
	parameter SIGNIFICAND_WIDTH = 23,
	parameter TOTAL_WIDTH = 1 + EXPONENT_WIDTH + SIGNIFICAND_WIDTH,
	parameter SIGNIFICAND_PRODUCT_WIDTH = (SIGNIFICAND_WIDTH + 1) * 2)

	(input										clk,
	input [TOTAL_WIDTH - 1:0]					operand1_i,
	input [TOTAL_WIDTH - 1:0]					operand2_i,
	output reg[SIGNIFICAND_PRODUCT_WIDTH + 1:0]	significand_o,
	output reg[EXPONENT_WIDTH - 1:0] 			exponent_o,
	output reg									sign_o);

	wire 										sign1;
	wire[EXPONENT_WIDTH - 1:0] 					exponent1;
	wire[SIGNIFICAND_WIDTH - 1:0] 				significand1;
	wire 										sign2;
	wire[EXPONENT_WIDTH - 1:0] 					exponent2;
	wire[SIGNIFICAND_WIDTH - 1:0] 				significand2;
	wire[EXPONENT_WIDTH - 1:0] 					unbiased_exponent1;
	wire[EXPONENT_WIDTH - 1:0] 					unbiased_exponent2;
	wire[EXPONENT_WIDTH - 1:0] 					unbiased_result_exponent;
	reg[EXPONENT_WIDTH - 1:0] 					result_exponent;
	wire 										is_zero_nxt;
	reg[SIGNIFICAND_PRODUCT_WIDTH + 1:0]	 	significand_product_nxt;
	wire 										result_sign;

	assign sign1 = operand1_i[EXPONENT_WIDTH + SIGNIFICAND_WIDTH];
	assign exponent1 = operand1_i[EXPONENT_WIDTH + SIGNIFICAND_WIDTH - 1:SIGNIFICAND_WIDTH];
	assign significand1 = operand1_i[SIGNIFICAND_WIDTH - 1:0];
	assign sign2 = operand2_i[EXPONENT_WIDTH + SIGNIFICAND_WIDTH];
	assign exponent2 = operand2_i[EXPONENT_WIDTH + SIGNIFICAND_WIDTH - 1:SIGNIFICAND_WIDTH];
	assign significand2 = operand2_i[SIGNIFICAND_WIDTH - 1:0];

	assign result_sign = sign1 ^ sign2;
	
	// Unbias the exponents so we can add them
	assign unbiased_exponent1 = { ~exponent1[EXPONENT_WIDTH - 1], 
			exponent1[EXPONENT_WIDTH - 2:0] };
	assign unbiased_exponent2 = { ~exponent2[EXPONENT_WIDTH - 1], 
			exponent2[EXPONENT_WIDTH - 2:0] };
			
	// The result exponent is simply the sum of the two exponents
	assign unbiased_result_exponent = unbiased_exponent1 + unbiased_exponent2;

	// Check for zero explicitly, since a leading 1 is otherwise 
	// assumed for the significand
	assign is_zero_nxt = operand1_i == 0 || operand2_i == 0;


	// Re-bias the result exponent.  Note that we subtract the significand width
	// here because of the multiplication.
	always @*
	begin
		if (is_zero_nxt)
			result_exponent = 0;
		else
			result_exponent = { ~unbiased_result_exponent[EXPONENT_WIDTH - 1], 
				unbiased_result_exponent[EXPONENT_WIDTH - 2:0] } + 1;
	end
	
	// Multiply the significands	
	// XXX this would normally be broken into a multi-stage wallace tree multiplier,
	// but use this for now.
	always @*
	begin
		if (is_zero_nxt)
			significand_product_nxt = 0;
		else
			significand_product_nxt = { 1'b1, significand1 } * { 1'b1, significand2 };
	end
	
	always @(posedge clk)
	begin
		significand_o 			<= #1 significand_product_nxt;
		exponent_o				<= #1 result_exponent;
		sign_o 					<= #1 result_sign;
	end
endmodule
