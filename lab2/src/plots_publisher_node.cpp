#include <geometry_msgs/Point.h>
#include <ros/ros.h>
#include <tf2_ros/transform_listener.h>
#include <visualization_msgs/MarkerArray.h>

#include <deque>
#include <string>

class PlotsPublisherNode {
  // 一条轨迹对应一个 TrajTrail：每次 update() 向 tf 要最新相对位姿，
  // 把平移部分存进定长队列，再由 getMarker() 打成 marker 发出。
  class TrajTrail {
    PlotsPublisherNode* parent;
    std::deque<geometry_msgs::Point> poses;
    std::string ref_frame, dest_frame;
    size_t buffer_size;

    visualization_msgs::Marker marker_out;

    void update() {
      geometry_msgs::TransformStamped transform;
      try {
        // ~~~~~~~~ BEGIN OF EDIT SECTION ~~~~~~~~
        // 要画的是"ref 系里 dest 原点的轨迹"。lookupTransform 按
        // (target, source) 取的是 source 原点相对 target 系的位姿，
        // 所以 (ref_frame, dest_frame) 正好给出下一个轨迹点；
        // ros::Time(0) 表示取缓冲里最新一帧，而不是某个指定时刻。
        transform =
            parent->tf_buffer_.lookupTransform(ref_frame, dest_frame, ros::Time(0));
        // ~~~~~~~~~ END OF EDIT SECTION ~~~~~~~~~

        while (poses.size() >= buffer_size) {
          poses.pop_front();
        }

        geometry_msgs::Point tmp;
        tmp.x = transform.transform.translation.x;
        tmp.y = transform.transform.translation.y;
        tmp.z = transform.transform.translation.z;
        poses.push_back(tmp);
      } catch (const tf2::TransformException& ex) {
        ROS_ERROR_STREAM("transform lookup failed: " << ex.what());
      }
    }

   public:
    TrajTrail() : parent(nullptr){};

    TrajTrail(PlotsPublisherNode* parent_,
              const std::string& ref_frame_,
              const std::string& dest_frame_,
              int buffer_size_ = 160)
        : parent(parent_),
          ref_frame(ref_frame_),
          dest_frame(dest_frame_),
          buffer_size(buffer_size_) {
      if (buffer_size <= 0) {
        ROS_ERROR_STREAM("invalid buffer size! defaulting to 10");
        buffer_size = 10;
      }

      marker_out.header.frame_id = ref_frame;
      marker_out.ns = "trails";
      marker_out.id = parent->trail_count_++;
      marker_out.type = visualization_msgs::Marker::LINE_STRIP;
      marker_out.action = visualization_msgs::Marker::ADD;
      marker_out.color.a = 0.8;
      marker_out.scale.x = 0.02;
      marker_out.lifetime = ros::Duration(1.0);
    }

    void setColor(float r_, float g_, float b_) {
      marker_out.color.r = r_;
      marker_out.color.g = g_;
      marker_out.color.b = b_;
    }

    void setNamespace(const std::string& ns_) { marker_out.ns = ns_; }

    void setDashed() { marker_out.type = visualization_msgs::Marker::LINE_LIST; }

    visualization_msgs::Marker getMarker() {
      update();
      marker_out.header.stamp = ros::Time::now();
      marker_out.points.clear();
      for (auto& p : poses) marker_out.points.push_back(p);

      if (marker_out.type == visualization_msgs::Marker::LINE_LIST && poses.size() % 2)
        marker_out.points.resize(poses.size() - 1);

      return marker_out;
    }
  };

 public:
  PlotsPublisherNode() : tf_listener_(tf_buffer_), trail_count_(0) {
    markers_pub_ = nh_.advertise<visualization_msgs::MarkerArray>("visuals", 0);
    heartbeat_ =
        nh_.createTimer(ros::Duration(0.02), &PlotsPublisherNode::onPublish, this);
    heartbeat_.start();

    av1_world_ = TrajTrail(this, "world", "av1", 300);
    av1_world_.setColor(0.25, 0.52, 1.0);
    av1_world_.setNamespace("Trail av1-world");
    av2_world_ = TrajTrail(this, "world", "av2", 300);
    av2_world_.setColor(0.8, 0.4, 0.26);
    av2_world_.setNamespace("Trail av2-world");
    av2_av1_ = TrajTrail(this, "av1", "av2", 160);
    av2_av1_.setDashed();
    av2_av1_.setColor(0.8, 0.4, 0.26);
    av2_av1_.setNamespace("Trail av2-av1");

    ROS_INFO_STREAM("Waiting for av1 and av2 transforms to be broadcast...");
    while (ros::ok()) {
      const bool av1_present = tf_buffer_.canTransform("av1", "world", ros::Time(0));
      const bool av2_present = tf_buffer_.canTransform("av2", "world", ros::Time(0));
      if (av1_present && av2_present) {
        ROS_INFO_STREAM("Necessary frames are present, starting!");
        break;
      }
    }
  }

  void onPublish(const ros::TimerEvent&) {
    visualization_msgs::MarkerArray visuals;
    visuals.markers.resize(2);
    visualization_msgs::Marker& av1(visuals.markers[0]);
    visualization_msgs::Marker& av2(visuals.markers[1]);
    av1.header.frame_id = "av1";
    av1.ns = "AVs";
    av1.id = 0;
    av1.header.stamp = ros::Time();
    av1.type = visualization_msgs::Marker::MESH_RESOURCE;
    av1.mesh_resource = "package://two_drones_pkg/mesh/quadrotor.dae";
    av1.action = visualization_msgs::Marker::ADD;
    av1.pose.orientation.w = 1.0;
    av1.scale.x = av1.scale.y = av1.scale.z = av1.color.a = 1.0;
    av1.color.r = 0.25;
    av1.color.g = 0.52;
    av1.color.b = 1.0;
    av1.lifetime = ros::Duration(1.0);
    av2 = av1;
    av2.header.frame_id = "av2";
    av2.ns = "AVs";
    av2.id = 1;
    av2.color.r = 0.8;
    av2.color.g = 0.4;
    av2.color.b = 0.26;

    // 三条拖尾挂在两个网格 marker 后面一起发
    visuals.markers.push_back(av1_world_.getMarker());
    visuals.markers.push_back(av2_world_.getMarker());
    visuals.markers.push_back(av2_av1_.getMarker());
    markers_pub_.publish(visuals);
  }

 private:
  ros::NodeHandle nh_;
  ros::Timer heartbeat_;
  ros::Publisher markers_pub_;
  tf2_ros::Buffer tf_buffer_;
  tf2_ros::TransformListener tf_listener_;
  int trail_count_;

  TrajTrail av1_world_;
  TrajTrail av2_world_;
  TrajTrail av2_av1_;
};

int main(int argc, char** argv) {
  ros::init(argc, argv, "plots_publisher_node");
  PlotsPublisherNode node;
  ros::spin();
  return 0;
}
