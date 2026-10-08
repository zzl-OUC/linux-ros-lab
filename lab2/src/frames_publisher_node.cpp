#include <ros/ros.h>
#include <tf2_ros/transform_broadcaster.h>
#include <tf2/LinearMath/Quaternion.h>

#include <cmath>
#include <string>

namespace {

// 造一条"父系 world、子系 child、平移 (x,y,z)"的带戳变换；
// 旋转留给调用方按需要填（AV1 随时间转，AV2 恒为单位四元数）。
geometry_msgs::TransformStamped makeStampedTransform(const ros::Time& stamp,
                                                     const std::string& child,
                                                     double x, double y,
                                                     double z) {
  geometry_msgs::TransformStamped t;
  t.header.stamp = stamp;
  t.header.frame_id = "world";
  t.child_frame_id = child;
  t.transform.translation.x = x;
  t.transform.translation.y = y;
  t.transform.translation.z = z;
  return t;
}

}  // namespace

class FramesPublisher {
 public:
  FramesPublisher() {
    t0_ = ros::Time::now();
    // 20 ms 一拍，即 50 Hz：每次回调重算两条变换并广播。
    timer_ = nh_.createTimer(ros::Duration(0.02), &FramesPublisher::tick, this);
    timer_.start();
  }

  void tick(const ros::TimerEvent&) {
    const ros::Time now = ros::Time::now();
    const double t = (now - t0_).toSec();

    // AV1：绕半径 1、角速度 1 rad/s 的单位圆；姿态取 yaw = t，
    // 于是机体 y 轴恰好指向速度方向、z 轴与世界 z 平行（roll = pitch = 0）。
    geometry_msgs::TransformStamped av1 =
        makeStampedTransform(now, "av1", std::cos(t), std::sin(t), 0.0);
    tf2::Quaternion heading;
    heading.setRPY(0.0, 0.0, t);
    av1.transform.rotation.x = heading.x();
    av1.transform.rotation.y = heading.y();
    av1.transform.rotation.z = heading.z();
    av1.transform.rotation.w = heading.w();

    // AV2：x = sin t、z = cos 2t 的抛物线弧，y 恒为 0；机体轴始终与世界系
    // 保持平行，所以旋转就是单位四元数（消息字段默认全 0，补一个 w = 1）。
    geometry_msgs::TransformStamped av2 = makeStampedTransform(
        now, "av2", std::sin(t), 0.0, std::cos(2.0 * t));
    av2.transform.rotation.w = 1.0;

    tf_pub_.sendTransform(av1);
    tf_pub_.sendTransform(av2);
  }

 private:
  ros::NodeHandle nh_;
  ros::Time t0_;
  ros::Timer timer_;
  tf2_ros::TransformBroadcaster tf_pub_;
};

int main(int argc, char** argv) {
  ros::init(argc, argv, "frames_publisher_node");
  FramesPublisher node;
  ros::spin();
  return 0;
}
