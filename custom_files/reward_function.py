
import math


class Reward:
    def __init__(self, verbose=False):
        self.first_racingpoint_index = 0
        self.verbose = verbose

    def reward_function(self, params):

        ################## HELPER FUNCTIONS ###################

        def dist_2_points(x1, x2, y1, y2):
            return abs(abs(x1-x2)**2 + abs(y1-y2)**2)**0.5

        def closest_2_racing_points_index(racing_coords, car_coords):

            # Calculate all distances to racing points
            distances = []
            for i in range(len(racing_coords)):
                distance = dist_2_points(x1=racing_coords[i][0], x2=car_coords[0],
                                         y1=racing_coords[i][1], y2=car_coords[1])
                distances.append(distance)

            # Get index of the closest racing point
            closest_index = distances.index(min(distances))

            # Get index of the second closest racing point
            distances_no_closest = distances.copy()
            distances_no_closest[closest_index] = 999
            second_closest_index = distances_no_closest.index(
                min(distances_no_closest))

            return [closest_index, second_closest_index]

        def dist_to_racing_line(closest_coords, second_closest_coords, car_coords):

            # Calculate the distances between 2 closest racing points
            a = abs(dist_2_points(x1=closest_coords[0],
                                  x2=second_closest_coords[0],
                                  y1=closest_coords[1],
                                  y2=second_closest_coords[1]))

            # Distances between car and closest and second closest racing point
            b = abs(dist_2_points(x1=car_coords[0],
                                  x2=closest_coords[0],
                                  y1=car_coords[1],
                                  y2=closest_coords[1]))
            c = abs(dist_2_points(x1=car_coords[0],
                                  x2=second_closest_coords[0],
                                  y1=car_coords[1],
                                  y2=second_closest_coords[1]))

            # Calculate distance between car and racing line (goes through 2 closest racing points)
            # try-except in case a=0 (rare bug in DeepRacer)
            try:
                distance = abs(-(a**4) + 2*(a**2)*(b**2) + 2*(a**2)*(c**2) -
                               (b**4) + 2*(b**2)*(c**2) - (c**4))**0.5 / (2*a)
            except:
                distance = b

            return distance

        # Calculate which one of the closest racing points is the next one and which one the previous one
        def next_prev_racing_point(closest_coords, second_closest_coords, car_coords, heading):

            # Virtually set the car more into the heading direction
            heading_vector = [math.cos(math.radians(
                heading)), math.sin(math.radians(heading))]
            new_car_coords = [car_coords[0]+heading_vector[0],
                              car_coords[1]+heading_vector[1]]

            # Calculate distance from new car coords to 2 closest racing points
            distance_closest_coords_new = dist_2_points(x1=new_car_coords[0],
                                                        x2=closest_coords[0],
                                                        y1=new_car_coords[1],
                                                        y2=closest_coords[1])
            distance_second_closest_coords_new = dist_2_points(x1=new_car_coords[0],
                                                               x2=second_closest_coords[0],
                                                               y1=new_car_coords[1],
                                                               y2=second_closest_coords[1])

            if distance_closest_coords_new <= distance_second_closest_coords_new:
                next_point_coords = closest_coords
                prev_point_coords = second_closest_coords
            else:
                next_point_coords = second_closest_coords
                prev_point_coords = closest_coords

            return [next_point_coords, prev_point_coords]

        def racing_direction_diff(closest_coords, second_closest_coords, car_coords, heading):

            # Calculate the direction of the center line based on the closest waypoints
            next_point, prev_point = next_prev_racing_point(closest_coords,
                                                            second_closest_coords,
                                                            car_coords,
                                                            heading)

            # Calculate the direction in radius, arctan2(dy, dx), the result is (-pi, pi) in radians
            track_direction = math.atan2(
                next_point[1] - prev_point[1], next_point[0] - prev_point[0])

            # Convert to degree
            track_direction = math.degrees(track_direction)

            # Calculate the difference between the track direction and the heading direction of the car
            direction_diff = abs(track_direction - heading)
            if direction_diff > 180:
                direction_diff = 360 - direction_diff

            return direction_diff

        # Gives back indexes that lie between start and end index of a cyclical list
        # (start index is included, end index is not)
        def indexes_cyclical(start, end, array_len):

            if end < start:
                end += array_len

            return [index % array_len for index in range(start, end)]

        # Calculate how long car would take for entire lap, if it continued like it did until now
        def projected_time(first_index, closest_index, step_count, times_list):

            # Calculate how much time has passed since start
            current_actual_time = (step_count-1) / 15

            # Calculate which indexes were already passed
            indexes_traveled = indexes_cyclical(
                first_index, closest_index, len(times_list))

            # Calculate how much time should have passed if car would have followed optimals
            current_expected_time = sum(
                [times_list[i] for i in indexes_traveled])

            # Calculate how long one entire lap takes if car follows optimals
            total_expected_time = sum(times_list)

            # Calculate how long car would take for entire lap, if it continued like it did until now
            try:
                projected_time = (current_actual_time /
                                  current_expected_time) * total_expected_time
            except:
                projected_time = 9999

            return projected_time

        #################### RACING LINE ######################

        # Optimal racing line for the Spain track
        # Each row: [x,y,speed,timeFromPreviousPoint]
        racing_track = [[-5.64726, 3.94983, 3.30451, 0.04534],
                        [-5.74096, 3.83315, 3.09639, 0.04833],
                        [-5.83336, 3.7157, 2.90816, 0.05138],
                        [-5.92425, 3.59744, 2.73776, 0.05448],
                        [-6.01337, 3.47826, 2.58325, 0.0576],
                        [-6.10043, 3.35812, 2.44289, 0.06074],
                        [-6.18511, 3.23692, 2.31522, 0.06386],
                        [-6.26708, 3.11462, 2.19904, 0.06695],
                        [-6.34595, 2.99116, 2.09342, 0.06998],
                        [-6.42131, 2.86652, 1.99768, 0.07291],
                        [-6.49275, 2.74068, 1.91132, 0.07571],
                        [-6.55982, 2.61365, 1.83405, 0.07832],
                        [-6.62206, 2.48547, 1.76569, 0.0807],
                        [-6.67899, 2.35622, 1.70617, 0.08278],
                        [-6.73015, 2.226, 1.6555, 0.08451],
                        [-6.77507, 2.09495, 1.6137, 0.08585],
                        [-6.8133, 1.96326, 1.58081, 0.08674],
                        [-6.8444, 1.83114, 1.55686, 0.08718],
                        [-6.86799, 1.69884, 1.54179, 0.08716],
                        [-6.8837, 1.56665, 1.5355, 0.0867],
                        [-6.89124, 1.43488, 1.5355, 0.08596],
                        [-6.89036, 1.30387, 1.5355, 0.08532],
                        [-6.88089, 1.17398, 1.5355, 0.08482],
                        [-6.86271, 1.04558, 1.5355, 0.08445],
                        [-6.8358, 0.91904, 1.5355, 0.08425],
                        [-6.80019, 0.79474, 1.5378, 0.08408],
                        [-6.75602, 0.67302, 1.54836, 0.08363],
                        [-6.70346, 0.55423, 1.56676, 0.08291],
                        [-6.64277, 0.43869, 1.59242, 0.08196],
                        [-6.57426, 0.32669, 1.62461, 0.08081],
                        [-6.49831, 0.21849, 1.66244, 0.07952],
                        [-6.41531, 0.11433, 1.7048, 0.07813],
                        [-6.3257, 0.0144, 1.75037, 0.07668],
                        [-6.22997, -0.08111, 1.79761, 0.07523],
                        [-6.12857, -0.17204, 1.84476, 0.07383],
                        [-6.02202, -0.25826, 1.88987, 0.07253],
                        [-5.9108, -0.33963, 1.93094, 0.07137],
                        [-5.79541, -0.41603, 1.96604, 0.07039],
                        [-5.67632, -0.48733, 1.99352, 0.06962],
                        [-5.55402, -0.55339, 1.98654, 0.06997],
                        [-5.42895, -0.61409, 1.97022, 0.07056],
                        [-5.30157, -0.66928, 1.95672, 0.07095],
                        [-5.1723, -0.71882, 1.94937, 0.07102],
                        [-5.04154, -0.76259, 1.94937, 0.07074],
                        [-4.90968, -0.80045, 1.94937, 0.07038],
                        [-4.77707, -0.8323, 1.94937, 0.06996],
                        [-4.64406, -0.85808, 1.94937, 0.0695],
                        [-4.51094, -0.87778, 1.94937, 0.06903],
                        [-4.37798, -0.89142, 1.95171, 0.06848],
                        [-4.24541, -0.89912, 1.96769, 0.06749],
                        [-4.11339, -0.90107, 2.00212, 0.06594],
                        [-3.98207, -0.89755, 2.0616, 0.06372],
                        [-3.85152, -0.88894, 2.1563, 0.06068],
                        [-3.72175, -0.87575, 2.30394, 0.05661],
                        [-3.59274, -0.85857, 2.55306, 0.05098],
                        [-3.46438, -0.83817, 2.64856, 0.04907],
                        [-3.33657, -0.81517, 2.36623, 0.05488],
                        [-3.2092, -0.7902, 2.16343, 0.05999],
                        [-3.0822, -0.76363, 1.98205, 0.06546],
                        [-2.95312, -0.73798, 1.83645, 0.07166],
                        [-2.82412, -0.71449, 1.7465, 0.07508],
                        [-2.69523, -0.69415, 1.69656, 0.07691],
                        [-2.56654, -0.6777, 1.67852, 0.0773],
                        [-2.4381, -0.66583, 1.67852, 0.07684],
                        [-2.31003, -0.65932, 1.67852, 0.0764],
                        [-2.18244, -0.65896, 1.67852, 0.07602],
                        [-2.05545, -0.66532, 1.67852, 0.07575],
                        [-1.92917, -0.67873, 1.67852, 0.07566],
                        [-1.80369, -0.69935, 1.68918, 0.07528],
                        [-1.6791, -0.72713, 1.72815, 0.07387],
                        [-1.55543, -0.76183, 1.79744, 0.07146],
                        [-1.43268, -0.80306, 1.90213, 0.06808],
                        [-1.31081, -0.85027, 2.05245, 0.06367],
                        [-1.18975, -0.90273, 2.26949, 0.05814],
                        [-1.0694, -0.95961, 2.60231, 0.05116],
                        [-0.94959, -1.01993, 3.18505, 0.04211],
                        [-0.83017, -1.08259, 2.98227, 0.04522],
                        [-0.71096, -1.14653, 2.7682, 0.04887],
                        [-0.58422, -1.21498, 2.6363, 0.05464],
                        [-0.45704, -1.28244, 2.5573, 0.0563],
                        [-0.32916, -1.34838, 2.51727, 0.05716],
                        [-0.20032, -1.4122, 2.50865, 0.05731],
                        [-0.07028, -1.47333, 2.50865, 0.05728],
                        [0.06114, -1.53134, 2.50865, 0.05726],
                        [0.19407, -1.58592, 2.50865, 0.05728],
                        [0.32856, -1.63681, 2.50865, 0.05732],
                        [0.46466, -1.6839, 2.50865, 0.05741],
                        [0.60236, -1.72711, 2.52694, 0.05711],
                        [0.74159, -1.76647, 2.56935, 0.05632],
                        [0.8823, -1.80205, 2.63395, 0.0551],
                        [1.02438, -1.83401, 2.71932, 0.05355],
                        [1.16771, -1.8625, 2.82416, 0.05174],
                        [1.31217, -1.88775, 2.94703, 0.04976],
                        [1.45762, -1.90999, 3.08606, 0.04768],
                        [1.60394, -1.92943, 3.23864, 0.04558],
                        [1.751, -1.94631, 3.40109, 0.04352],
                        [1.89869, -1.96084, 3.56836, 0.04159],
                        [2.04689, -1.97322, 3.73388, 0.03983],
                        [2.19551, -1.98361, 3.88967, 0.0383],
                        [2.34445, -1.99216, 4.0, 0.0373],
                        [2.49365, -1.99899, 4.0, 0.03734],
                        [2.64304, -2.00417, 4.0, 0.03737],
                        [2.79254, -2.00776, 3.87802, 0.03856],
                        [2.94211, -2.00979, 3.73364, 0.04006],
                        [3.09168, -2.01024, 3.58034, 0.04178],
                        [3.24121, -2.00908, 3.42291, 0.04369],
                        [3.39063, -2.00626, 3.2651, 0.04577],
                        [3.53989, -2.00168, 3.10971, 0.04802],
                        [3.68892, -1.99524, 2.95878, 0.05041],
                        [3.83762, -1.9868, 2.81373, 0.05294],
                        [3.98592, -1.97619, 2.6755, 0.05557],
                        [4.13369, -1.96324, 2.5447, 0.05829],
                        [4.28081, -1.94774, 2.42169, 0.06109],
                        [4.42713, -1.92945, 2.30668, 0.06392],
                        [4.57245, -1.90815, 2.19975, 0.06677],
                        [4.71658, -1.88356, 2.10092, 0.0696],
                        [4.85928, -1.85541, 2.01021, 0.07236],
                        [5.00029, -1.82343, 1.92758, 0.07501],
                        [5.13929, -1.78732, 1.85301, 0.0775],
                        [5.27596, -1.74681, 1.78643, 0.0798],
                        [5.40994, -1.70163, 1.72776, 0.08184],
                        [5.54084, -1.65152, 1.67685, 0.08359],
                        [5.66825, -1.59626, 1.63349, 0.08502],
                        [5.79172, -1.53566, 1.59734, 0.08611],
                        [5.91082, -1.46956, 1.56793, 0.08687],
                        [6.02509, -1.39785, 1.54465, 0.08733],
                        [6.13406, -1.3205, 1.52673, 0.08753],
                        [6.23728, -1.23751, 1.51323, 0.08752],
                        [6.3343, -1.14898, 1.5031, 0.08739],
                        [6.42471, -1.05504, 1.49519, 0.08719],
                        [6.50809, -0.95593, 1.48837, 0.08702],
                        [6.58406, -0.85194, 1.48154, 0.08693],
                        [6.65228, -0.74343, 1.47378, 0.08697],
                        [6.71242, -0.63083, 1.4644, 0.08717],
                        [6.7642, -0.51465, 1.45301, 0.08754],
                        [6.80736, -0.39543, 1.43961, 0.08807],
                        [6.8417, -0.27379, 1.4245, 0.08873],
                        [6.86702, -0.15037, 1.40835, 0.08946],
                        [6.88319, -0.02588, 1.39211, 0.09018],
                        [6.8901, 0.09898, 1.37691, 0.09082],
                        [6.88767, 0.22345, 1.36404, 0.09127],
                        [6.87588, 0.34677, 1.35485, 0.09144],
                        [6.85475, 0.46819, 1.3507, 0.09125],
                        [6.82434, 0.58696, 1.3507, 0.09077],
                        [6.78475, 0.70233, 1.3507, 0.0903],
                        [6.73616, 0.8136, 1.3507, 0.08989],
                        [6.67879, 0.92011, 1.3507, 0.08957],
                        [6.6129, 1.02126, 1.3507, 0.08937],
                        [6.53883, 1.11649, 1.35292, 0.08918],
                        [6.45696, 1.20535, 1.3628, 0.08866],
                        [6.36771, 1.28748, 1.38158, 0.08779],
                        [6.27156, 1.3626, 1.41046, 0.08651],
                        [6.16901, 1.43057, 1.45071, 0.0848],
                        [6.06061, 1.49135, 1.50373, 0.08265],
                        [5.94691, 1.54503, 1.5712, 0.08003],
                        [5.82847, 1.59183, 1.65533, 0.07693],
                        [5.70586, 1.63206, 1.75907, 0.07336],
                        [5.57963, 1.66618, 1.88644, 0.06931],
                        [5.45033, 1.69473, 2.04291, 0.06482],
                        [5.31845, 1.7183, 2.23626, 0.05991],
                        [5.18446, 1.73757, 2.479, 0.05461],
                        [5.04877, 1.75322, 2.79521, 0.04887],
                        [4.91174, 1.76595, 3.24138, 0.04246],
                        [4.77371, 1.77647, 3.99084, 0.03469],
                        [4.635, 1.7855, 4.0, 0.03475],
                        [4.49592, 1.79374, 4.0, 0.03483],
                        [4.35465, 1.8019, 3.92987, 0.03601],
                        [4.21332, 1.81056, 3.75825, 0.03768],
                        [4.07191, 1.81999, 3.61223, 0.03923],
                        [3.93041, 1.83047, 3.4815, 0.04076],
                        [3.78879, 1.84224, 3.36026, 0.04229],
                        [3.64708, 1.85552, 3.24568, 0.04385],
                        [3.5053, 1.87048, 3.13711, 0.04544],
                        [3.3635, 1.88727, 3.03527, 0.04704],
                        [3.22174, 1.90605, 2.94164, 0.04861],
                        [3.0801, 1.92698, 2.85773, 0.0501],
                        [2.93867, 1.95019, 2.78469, 0.05147],
                        [2.79756, 1.97585, 2.72306, 0.05267],
                        [2.65689, 2.00413, 2.67264, 0.05369],
                        [2.51678, 2.03517, 2.63248, 0.05452],
                        [2.37734, 2.06915, 2.60089, 0.05518],
                        [2.2387, 2.10621, 2.5755, 0.05572],
                        [2.10097, 2.14651, 2.55344, 0.0562],
                        [1.96427, 2.19016, 2.53149, 0.05669],
                        [1.82871, 2.23728, 2.5065, 0.05726],
                        [1.69441, 2.28794, 2.47576, 0.05798],
                        [1.56149, 2.34219, 2.43751, 0.0589],
                        [1.43008, 2.40008, 2.39119, 0.06005],
                        [1.30034, 2.46159, 2.33767, 0.06142],
                        [1.17244, 2.52674, 2.27899, 0.06298],
                        [1.04657, 2.5955, 2.21811, 0.06466],
                        [0.92296, 2.66785, 2.15847, 0.06636],
                        [0.80186, 2.74377, 2.10355, 0.06795],
                        [0.68354, 2.82326, 2.05668, 0.0693],
                        [0.56831, 2.90631, 2.02087, 0.07029],
                        [0.45647, 2.99293, 1.99885, 0.07077],
                        [0.34835, 3.08313, 1.99327, 0.07064],
                        [0.24424, 3.17695, 1.99327, 0.07031],
                        [0.14443, 3.27438, 1.99327, 0.06998],
                        [0.04918, 3.37545, 1.99327, 0.06967],
                        [-0.04133, 3.48013, 1.99327, 0.06942],
                        [-0.12694, 3.58838, 1.99327, 0.06924],
                        [-0.20761, 3.70013, 2.0071, 0.06867],
                        [-0.28336, 3.81526, 2.04415, 0.06742],
                        [-0.35433, 3.9336, 2.10906, 0.06543],
                        [-0.42076, 4.05492, 2.20559, 0.06271],
                        [-0.48298, 4.17895, 2.33645, 0.05939],
                        [-0.54139, 4.30539, 2.50484, 0.0556],
                        [-0.59643, 4.43392, 2.4273, 0.0576],
                        [-0.64841, 4.56432, 2.27959, 0.06158],
                        [-0.69751, 4.69642, 2.14258, 0.06577],
                        [-0.74375, 4.83007, 1.99529, 0.07088],
                        [-0.7868, 4.96485, 1.88984, 0.07487],
                        [-0.83274, 5.09654, 1.76818, 0.07888],
                        [-0.88199, 5.22527, 1.67679, 0.0822],
                        [-0.93486, 5.35073, 1.59116, 0.08557],
                        [-0.99163, 5.47257, 1.51701, 0.0886],
                        [-1.05267, 5.59025, 1.45096, 0.09137],
                        [-1.11818, 5.70334, 1.39684, 0.09356],
                        [-1.18848, 5.81122, 1.35572, 0.09498],
                        [-1.26373, 5.91334, 1.32657, 0.09562],
                        [-1.34406, 6.00911, 1.30827, 0.09554],
                        [-1.42951, 6.09792, 1.3, 0.09481],
                        [-1.52009, 6.17915, 1.3, 0.09359],
                        [-1.61567, 6.25221, 1.3, 0.09255],
                        [-1.71604, 6.31658, 1.3, 0.09172],
                        [-1.82088, 6.3718, 1.3, 0.09115],
                        [-1.92977, 6.41749, 1.3, 0.09084],
                        [-2.04224, 6.45339, 1.30114, 0.09074],
                        [-2.15776, 6.4793, 1.31125, 0.09029],
                        [-2.27577, 6.49513, 1.33, 0.08952],
                        [-2.39569, 6.50086, 1.35721, 0.08846],
                        [-2.51696, 6.4966, 1.39285, 0.08712],
                        [-2.63903, 6.48254, 1.43697, 0.08552],
                        [-2.76141, 6.45894, 1.48977, 0.08366],
                        [-2.88362, 6.42615, 1.55154, 0.08155],
                        [-3.00527, 6.3846, 1.62268, 0.07922],
                        [-3.12602, 6.33478, 1.70375, 0.07667],
                        [-3.2456, 6.27721, 1.79541, 0.07392],
                        [-3.36379, 6.21246, 1.89851, 0.07098],
                        [-3.48045, 6.14112, 2.01409, 0.06789],
                        [-3.59549, 6.0638, 2.14342, 0.06467],
                        [-3.70889, 5.9811, 2.28801, 0.06134],
                        [-3.82065, 5.8936, 2.44967, 0.05794],
                        [-3.93081, 5.80188, 2.63041, 0.0545],
                        [-4.03947, 5.70647, 2.8325, 0.05105],
                        [-4.14671, 5.60786, 3.05825, 0.04764],
                        [-4.25265, 5.50651, 3.3098, 0.0443],
                        [-4.35741, 5.40284, 3.58858, 0.04107],
                        [-4.4611, 5.29719, 3.8945, 0.03801],
                        [-4.56383, 5.18991, 4.0, 0.03714],
                        [-4.66572, 5.08123, 4.0, 0.03724],
                        [-4.76684, 4.97141, 4.0, 0.03732],
                        [-4.86726, 4.86061, 4.0, 0.03738],
                        [-4.96705, 4.74898, 4.0, 0.03743],
                        [-5.06623, 4.63664, 4.0, 0.03747],
                        [-5.16481, 4.52364, 4.0, 0.03749],
                        [-5.26278, 4.41006, 4.0, 0.0375],
                        [-5.36008, 4.29589, 4.0, 0.0375],
                        [-5.45666, 4.18114, 3.78751, 0.0396],
                        [-5.55242, 4.0658, 3.53442, 0.04242]]
        ################## INPUT PARAMETERS ###################

        # Read all input parameters
        all_wheels_on_track = params['all_wheels_on_track']
        x = params['x']
        y = params['y']
        distance_from_center = params['distance_from_center']
        is_left_of_center = params['is_left_of_center']
        heading = params['heading']
        progress = params['progress']
        steps = params['steps']
        speed = params['speed']
        steering_angle = params['steering_angle']
        track_width = params['track_width']
        waypoints = params['waypoints']
        closest_waypoints = params['closest_waypoints']
        is_offtrack = params['is_offtrack']

        ############### OPTIMAL X,Y,SPEED,TIME ################

        # Get closest indexes for racing line (and distances to all points on racing line)
        closest_index, second_closest_index = closest_2_racing_points_index(
            racing_track, [x, y])

        # Get optimal [x, y, speed, time] for closest and second closest index
        optimals = racing_track[closest_index]
        optimals_second = racing_track[second_closest_index]

        # Save first racingpoint of episode for later
        if self.verbose == True:
            self.first_racingpoint_index = 0  # this is just for testing purposes
        if steps == 1:
            self.first_racingpoint_index = closest_index

        ################ REWARD AND PUNISHMENT ################

        ## Define the default reward ##
        reward = 1

        ## Reward if car goes close to optimal racing line ##
        DISTANCE_MULTIPLE = 1
        dist = dist_to_racing_line(optimals[0:2], optimals_second[0:2], [x, y])
        distance_reward = max(1e-3, 1 - (dist/(track_width*0.5)))
        reward += distance_reward * DISTANCE_MULTIPLE

        ## Reward if speed is close to optimal speed ##
        SPEED_DIFF_NO_REWARD = 1
        SPEED_MULTIPLE = 2
        speed_diff = abs(optimals[2]-speed)
        if speed_diff <= SPEED_DIFF_NO_REWARD:
            # we use quadratic punishment (not linear) bc we're not as confident with the optimal speed
            # so, we do not punish small deviations from optimal speed
            speed_reward = (1 - (speed_diff/(SPEED_DIFF_NO_REWARD))**2)**2
        else:
            speed_reward = 0
        reward += speed_reward * SPEED_MULTIPLE

        # Reward if less steps
        REWARD_PER_STEP_FOR_FASTEST_TIME = 1
        STANDARD_TIME = 25
        FASTEST_TIME = 15
        times_list = [row[3] for row in racing_track]
        projected_time = projected_time(
            self.first_racingpoint_index, closest_index, steps, times_list)
        try:
            steps_prediction = projected_time * 15 + 1
            reward_prediction = max(1e-3, (-REWARD_PER_STEP_FOR_FASTEST_TIME*(FASTEST_TIME) /
                                           (STANDARD_TIME-FASTEST_TIME))*(steps_prediction-(STANDARD_TIME*15+1)))
            steps_reward = min(REWARD_PER_STEP_FOR_FASTEST_TIME,
                               reward_prediction / steps_prediction)
        except:
            steps_reward = 0
        reward += steps_reward

        # Zero reward if obviously wrong direction (e.g. spin)
        direction_diff = racing_direction_diff(
            optimals[0:2], optimals_second[0:2], [x, y], heading)
        if direction_diff > 30:
            reward = 1e-3

        # Zero reward of obviously too slow
        speed_diff_zero = optimals[2]-speed
        if speed_diff_zero > 0.5:
            reward = 1e-3

        ## Incentive for finishing the lap in less steps ##
        # should be adapted to track length and other rewards
        REWARD_FOR_FASTEST_TIME = 1500
        STANDARD_TIME = 25  # seconds (time that is easily done by model)
        FASTEST_TIME = 15  # seconds (best time of 1st place on the track)
        if progress == 100:
            finish_reward = max(1e-3, (-REWARD_FOR_FASTEST_TIME /
                                       (15*(STANDARD_TIME-FASTEST_TIME)))*(steps-STANDARD_TIME*15))
        else:
            finish_reward = 0
        reward += finish_reward

        ## Zero reward if off track ##
        if all_wheels_on_track == False:
            reward = 1e-3

        ####################### VERBOSE #######################

        if self.verbose == True:
            print("Closest index: %i" % closest_index)
            print("Distance to racing line: %f" % dist)
            print("=== Distance reward (w/out multiple): %f ===" %
                  (distance_reward))
            print("Optimal speed: %f" % optimals[2])
            print("Speed difference: %f" % speed_diff)
            print("=== Speed reward (w/out multiple): %f ===" % speed_reward)
            print("Direction difference: %f" % direction_diff)
            print("Predicted time: %f" % projected_time)
            print("=== Steps reward: %f ===" % steps_reward)
            print("=== Finish reward: %f ===" % finish_reward)

        #################### RETURN REWARD ####################

        # Always return a float value
        return float(reward)


reward_object = Reward()  # add parameter verbose=True to get noisy output for testing


def reward_function(params):
    return reward_object.reward_function(params)
