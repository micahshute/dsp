##
# This strategy will solve a system of linear equations using the Gauss Seidel iterative strategy
# Constructor Inputs: (a_arr, b_arr) correspond to A and B in the equation Ax = B (a should be an nxn 2D array, and b should be a 1D array (even though in the equation it is a column vector))
#
## a = [[4,1,-1],[2,7,1],[1,-3,12]]
## b = [3,19,31]
## gs = Digiproc::Strategies::GaussSeidelStrategy.new(a,b)
## x = gs.calculate # => Matrix[[0.9998668946614292], [2.000021547671973], [3.000054218557957]]


class Digiproc::Strategies::GaussSeidelStrategy


    ##
    # ==Initialize args
    # a_arr:: 2D array representing your A matrix
    # b_arr:: 1D array representing your B matrix
    # Where B = Ax defines your series of linear equations
    def initialize(a_arr,b_arr)
        # TODO: Raise exception if a_arr is not square and b_arr row_count != a_arr row count
        @b = Matrix.column_vector(b_arr)
        @a = Matrix.rows(a_arr, true)
        d_arr, l_arr, u_arr = [],[],[]
        num_cols = @a.column_count
        @a.row_count.times do 
            d_arr << Array.new(num_cols, 0)
            l_arr << Array.new(num_cols, 0)
            u_arr << Array.new(num_cols, 0)
        end

        @a.each_with_index do |el, row, col| 
            if row > col
                l_arr[row][col] = el
            elsif row < col
                u_arr[row][col] = el
            else
                d_arr[row][col] = el
            end
        end
        @d = Matrix.rows(d_arr)
        @l = Matrix.rows(l_arr)
        @u = Matrix.rows(u_arr)
        #TODO: Ensure no zeros on diagonal
        @dinv = @d.map{ |el| el == 0 ? 0 : 1.0 / el }
    end

    ##
    # Iteratively solves the linear system of equations using the Gauss Seidel method
    # accepts an optional parameter which is the threshold value x(n+1) - x(n) should achieve before returning. 
    # Must be used with a key-value pair ie 
    ## gs.calculate(threshold: 0.001)
    # default threshold = 0.001
    # Returns a column vector Matrix => access via matrix_return[row,col]
    # If run with the option safety_net: true and the equation diverges, performs A_inverse * B to solve 
    # ie 
    ## s.calculate(safety_net: true)
    #
    def calculate(threshold: 0.001, safety_net: false)
        dinv, b, l, u = @dinv, @b, @l, @u
        c = dinv * b
        t = -1 * dinv * (l + u)
        x_n = Matrix.column_vector(Array.new(@a.column_count, 0))
        counter = 0

        #TODO: Investigate speed difference of using 
        # x_new = c + t*x_old , where:
        # c = (l + d).inv * b
        # t = -1 * (l + d).inv * u
        loop do 
            x_n_plus_1 = x_n.dup
            for i in 0...x_n.row_count do 
                x_n_i = c.row(i).to_matrix + t.row(i).to_matrix.transpose * x_n_plus_1
                # puts "#{c.row(i).to_matrix} + #{t.row(i).to_matrix.transpose} * #{x_n_plus_1} = #{x_n_i}"
                x_n_plus_1[i,0] = x_n_i[0,0]
            end
            x_difference = (x_n_plus_1 - x_n).map{ |el| el.abs }
            should_break = !x_difference.find{ |el| el > threshold }
            x_n = x_n_plus_1           
            break if should_break
            counter += 1
            if counter > 1000000 and safety_net 
                return (@a.inv * b).map{ |el| el.to_f}
            end
        end 
        return (safety_net and x_n.find{ |el| el.to_f.nan? }) ? (@a.inv * b).map{ |el| el.to_f} : x_n
    end



end