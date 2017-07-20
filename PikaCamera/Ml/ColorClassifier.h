#pragma once

#include <iostream>
#include <vector>
#include <tuple>


class ColorClassifier
{
public:
  ColorClassifier(const std::string& load_from_object);
  inline int compute_idx(const std::vector<unsigned char> & pixel);
  std::tuple<double, double, double, double> compute_percentage(const std::vector<std::vector<std::vector<unsigned char>>> & tile);
  bool is_blue(const std::vector<std::vector<std::vector<unsigned char>>> & tile, float alpha);
  bool is_red(const std::vector<std::vector<std::vector<unsigned char>>> & tile, float alpha);
  bool is_yellow(const std::vector<std::vector<std::vector<unsigned char>>> & tile, float alpha);
  ~ColorClassifier();
private:
  std::vector<float> p_none;
  std::vector<float> p_blue;
  std::vector<float> p_red;
  std::vector<float> p_yellow;
  const int STEP_SIZE = 5;
  const int BASE = 255 / STEP_SIZE + 1;
};
