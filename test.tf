resource "time_sleep" "wait_3_seconds" {
  count = 5
  create_duration = "3s"
}
