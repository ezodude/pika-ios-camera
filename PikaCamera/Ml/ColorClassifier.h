#pragma once

#include <iostream>
#include <vector>
#include <tuple>
#include <opencv2/core/core.hpp>

class ColorClassifier
{
public:
	ColorClassifier(const std::string& load_from_object);
	inline int compute_idx(const cv::Vec3b & pixel);
	std::tuple<double, double, double, double> compute_percentage(const cv::Mat & tile);
	bool is_blue(const cv::Mat & tile, float alpha);
	bool is_red(const cv::Mat & tile, float alpha);
	bool is_yellow(const cv::Mat & tile, float alpha);
	~ColorClassifier();
private:
	std::vector<float> p_none;
	std::vector<float> p_blue;
	std::vector<float> p_red;
	std::vector<float> p_yellow;
	const int STEP_SIZE = 5;
	const int BASE = 255 / STEP_SIZE + 1;
};

