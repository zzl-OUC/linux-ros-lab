#!/usr/bin/env python3
"""Independent check of the LAB2 scene: sample tf, recompute o2_1 by hand, and
compare against what tf actually reports.  Writes CSV + a JSON receipt."""
import json
import math
import sys
import time

import numpy as np
import rospy
import tf2_ros
from visualization_msgs.msg import MarkerArray


def main(seconds=20.0, out_csv="/tmp/lab2_tf_samples.csv"):
    rospy.init_node("lab2_verify", anonymous=True)
    buf = tf2_ros.Buffer()
    tf2_ros.TransformListener(buf)

    marks = {}

    def cb(msg):
        for m in msg.markers:
            if m.ns.startswith("Trail"):
                marks[m.ns] = (m.header.frame_id,
                               [(p.x, p.y, p.z) for p in m.points],
                               m.type)

    sub = rospy.Subscriber("/visuals", MarkerArray, cb, queue_size=1)

    rows = []
    t0 = rospy.Time.now()
    rate = rospy.Rate(50)
    while not rospy.is_shutdown():
        t = (rospy.Time.now() - t0).to_sec()
        try:
            # all three lookups must share one stamp, otherwise the residual
            # measures the sampling skew instead of the algebra
            a1 = buf.lookup_transform("world", "av1", rospy.Time(0))
            ts = a1.header.stamp
            w1 = buf.lookup_transform("world", "av1", ts)
            w2 = buf.lookup_transform("world", "av2", ts)
            r12 = buf.lookup_transform("av1", "av2", ts)
        except Exception:
            rate.sleep()
            continue
        tr1 = w1.transform.translation
        q1 = w1.transform.rotation
        tr2 = w2.transform.translation
        rr = r12.transform.translation
        # quaternion -> Rz only rotation, then recompute o2_1 by hand
        o1 = np.array([tr1.x, tr1.y, tr1.z])
        o2 = np.array([tr2.x, tr2.y, tr2.z])
        R = np.array([[1 - 2 * (q1.y**2 + q1.z**2), 2 * (q1.x * q1.y - q1.z * q1.w), 2 * (q1.x * q1.z + q1.y * q1.w)],
                      [2 * (q1.x * q1.y + q1.z * q1.w), 1 - 2 * (q1.x**2 + q1.z**2), 2 * (q1.y * q1.z - q1.x * q1.w)],
                      [2 * (q1.x * q1.z - q1.y * q1.w), 2 * (q1.y * q1.z + q1.x * q1.w), 1 - 2 * (q1.x**2 + q1.y**2)]])
        pred = R.T @ (o2 - o1)
        rows.append([t, o1[0], o1[1], o1[2], o2[0], o2[1], o2[2],
                     q1.x, q1.y, q1.z, q1.w,
                     rr.x, rr.y, rr.z, pred[0], pred[1], pred[2]])
        if t > seconds:
            break
        rate.sleep()

    A = np.array(rows)
    with open(out_csv, "w") as f:
        f.write("t,o1x,o1y,o1z,o2x,o2y,o2z,qx,qy,qz,qw,tf_x,tf_y,tf_z,pred_x,pred_y,pred_z\n")
        for r in A:
            f.write(",".join("%.17g" % v for v in r) + "\n")

    n = len(A)
    if n == 0:
        print(json.dumps({"samples": 0, "error": "no transforms ever resolved"}))
        return 1

    # ---- the five claims the report makes -------------------------------------
    o1 = A[:, 1:4]
    o2 = A[:, 4:7]
    tf12 = A[:, 11:14]
    pr12 = A[:, 14:17]

    r_circle = np.linalg.norm(o1[:, :2], axis=1)          # |o1_xy| should be 1
    z_of_x = o2[:, 2] - (1.0 - 2.0 * o2[:, 0] ** 2)       # z = 1 - 2x^2
    plane = tf12[:, 2] - 2.0 * tf12[:, 1] - 1.0               # z1 = 2 y1 + 1
    ell = (tf12[:, 0] + 1.0) ** 2 + (tf12[:, 1] + 0.5) ** 2  # = 1/4
    off = np.linalg.norm(tf12 - pr12, axis=1)              # tf vs hand-computed

    # semi-axes, measured directly in the plane
    c = np.array([-1.0, -0.5, 0.0])
    nrm = np.array([0.0, -2.0, 1.0]) / math.sqrt(5.0)
    ep = np.array([1.0, 0.0, 0.0])
    eq = np.cross(nrm, ep)
    eq = eq / np.linalg.norm(eq)
    d = tf12 - c
    xp = d @ ep
    yp = d @ eq
    radii = np.hypot(xp, yp)

    # the marker trails that RViz actually draws -- check each against the
    # closed form its namespace claims to represent
    trail_stats = {}
    for ns, (fid, pts, mtype) in sorted(marks.items()):
        if len(pts) < 8:
            trail_stats[ns] = {"frame_id": fid, "n_points": len(pts),
                               "verdict": "too few points"}
            continue
        P = np.array(pts)
        rec = {"frame_id": fid, "n_points": int(len(P)), "marker_type": int(mtype)}
        if ns == "Trail av1-world":
            rec["max_abs_radius_minus_1"] = float(np.abs(
                np.linalg.norm(P[:, :2], axis=1) - 1.0).max())
            rec["max_abs_z"] = float(np.abs(P[:, 2]).max())
        elif ns == "Trail av2-world":
            rec["max_abs_parabola_residual"] = float(
                np.abs(P[:, 2] - (1.0 - 2.0 * P[:, 0] ** 2)).max())
            rec["max_abs_y"] = float(np.abs(P[:, 1]).max())
        elif ns == "Trail av2-av1":
            rec["max_abs_plane_residual"] = float(
                np.abs(P[:, 2] - 2.0 * P[:, 1] - 1.0).max())
            rec["max_abs_cylinder_residual"] = float(
                np.abs((P[:, 0] + 1.0) ** 2 + (P[:, 1] + 0.5) ** 2 - 0.25).max())
            d = P - np.array([-1.0, -0.5, 0.0])
            rec["radius_min"] = float(np.linalg.norm(d, axis=1).min())
            rec["radius_max"] = float(np.linalg.norm(d, axis=1).max())
        trail_stats[ns] = rec

    out = {
        "samples": int(n),
        "span_s": float(A[-1, 0] - A[0, 0]),
        "av1_circle_radius_err_max": float(np.abs(r_circle - 1.0).max()),
        "av2_parabola_residual_max": float(np.abs(z_of_x).max()),
        "relative_planarity_z1_minus_2y1_minus_1_max": float(np.abs(plane).max()),
        "relative_cylinder_residual_max": float(np.abs(ell - 0.25).max()),
        "tf_vs_hand_computed_o21_max": float(off.max()),
        "in_plane_radius_min": float(radii.min()),
        "in_plane_radius_max": float(radii.max()),
        "semi_minor_expected": 0.5,
        "semi_major_expected": math.sqrt(5.0) / 2.0,
        "trails": trail_stats,
    }
    print(json.dumps(out, indent=2))
    with open("/tmp/lab2_verify.json", "w") as f:
        json.dump(out, f, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main(float(sys.argv[1]) if len(sys.argv) > 1 else 20.0))
