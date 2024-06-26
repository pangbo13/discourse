# frozen_string_literal: true

RSpec.describe TopicViewItem do
  def add(topic_id, ip, user_id = nil)
    skip_redis = true
    TopicViewItem.add(topic_id, ip, user_id, nil, skip_redis)
  end

  it "correctly increase topic view stats" do
    topic = Fabricate(:topic)

    freeze_time "2021-01-01 12:00"

    add(topic.id, "1.1.1.1", nil)
    add(topic.id, "1.1.1.1", nil)

    stat = TopicViewStat.find_by(topic_id: topic.id, viewed_at: Date.today)
    expect(stat.anonymous_views).to eq(2)
    expect(stat.logged_in_views).to eq(0)

    add(topic.id, "1.1.1.1", topic.user.id)
    stat.reload

    expect(stat.anonymous_views).to eq(2)
    expect(stat.logged_in_views).to eq(1)

    freeze_time(1.day.from_now)

    add(topic.id, "1.1.1.1", nil)
    stat = TopicViewStat.find_by(topic_id: topic.id, viewed_at: Date.today)

    expect(stat.anonymous_views).to eq(1)
    expect(stat.logged_in_views).to eq(0)
  end

  it "raises nothing for dupes" do
    add(2, "1.1.1.1")
    add(2, "1.1.1.1", 1)

    TopicViewItem.create!(topic_id: 1, ip_address: "1.1.1.1", viewed_at: 1.day.ago)
    add(1, "1.1.1.1")

    expect(TopicViewItem.count).to eq(3)
  end

  it "increases a users view count" do
    user = Fabricate(:user)

    add(1, "1.1.1.1", user.id)
    add(1, "1.1.1.1", user.id)

    user.user_stat.reload
    expect(user.user_stat.topics_entered).to eq(1)
  end

  it "does not log IP address for logged-in users" do
    topic = Fabricate(:topic)
    user = Fabricate(:user)
    add(topic.id, "1.1.1.1", user.id)

    expect(TopicViewItem.find_by(topic_id: topic.id, user_id: user.id).ip_address).to eq(nil)
    add(topic.id, "1.2.3.4", nil)
    expect(TopicViewItem.find_by(topic_id: topic.id, user_id: nil).ip_address).to eq("1.2.3.4")
  end
end
