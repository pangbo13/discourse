# frozen_string_literal: true

RSpec.describe Flag, type: :model do
  after(:each) { Flag.reset_flag_settings! }

  it "has id lower than 1000 for system flags" do
    flag = Fabricate(:flag, id: 1)
    expect(flag.system?).to be true
    flag.destroy!
  end

  it "has id greater than 1000 for non-system flags" do
    flag = Fabricate(:flag)
    expect(flag.system?).to be false
    expect(flag.id).to be > 1000
    flag.destroy!
  end

  it "has correct name key" do
    flag = Fabricate(:flag, name: "CuStOm Flag!!!")
    expect(flag.name_key).to eq("custom_flag")

    flag.update!(name: "It's Illegal")
    expect(flag.name_key).to eq("its_illegal")

    flag.update!(name: "THIS IS    SPaM!+)(*&^%$#@@@!)")
    expect(flag.name_key).to eq("this_is_spam")

    flag.destroy!
  end

  it "updates post action types when created, modified or destroyed" do
    expect(PostActionType.flag_types.keys).to eq(
      %i[notify_user off_topic inappropriate spam illegal notify_moderators],
    )
    expect(ReviewableScore.types.keys).to eq(
      %i[notify_user off_topic inappropriate spam illegal notify_moderators needs_approval],
    )

    flag = Fabricate(:flag, name: "custom")
    expect(PostActionType.flag_types.keys).to eq(
      %i[notify_user off_topic inappropriate spam illegal notify_moderators custom],
    )
    expect(ReviewableScore.types.keys).to eq(
      %i[notify_user off_topic inappropriate spam illegal notify_moderators custom needs_approval],
    )

    flag.update!(name: "edited_custom")
    expect(PostActionType.flag_types.keys).to eq(
      %i[notify_user off_topic inappropriate spam illegal notify_moderators edited_custom],
    )
    expect(ReviewableScore.types.keys).to eq(
      %i[
        notify_user
        off_topic
        inappropriate
        spam
        illegal
        notify_moderators
        edited_custom
        needs_approval
      ],
    )

    flag.destroy!
    expect(PostActionType.flag_types.keys).to eq(
      %i[notify_user off_topic inappropriate spam illegal notify_moderators],
    )
    expect(ReviewableScore.types.keys).to eq(
      %i[notify_user off_topic inappropriate spam illegal notify_moderators needs_approval],
    )
  end

  describe ".used_flag_ids" do
    fab!(:post_action) { Fabricate(:post_action, post_action_type_id: PostActionType.types[:like]) }
    fab!(:post_action_2) do
      Fabricate(:post_action, post_action_type_id: PostActionType.types[:like])
    end
    fab!(:post_action_3) do
      Fabricate(:post_action, post_action_type_id: PostActionType.types[:off_topic])
    end
    fab!(:reviewable_score) do
      Fabricate(:reviewable_score, reviewable_score_type: PostActionType.types[:off_topic])
    end
    fab!(:reviewable_score_2) do
      Fabricate(:reviewable_score, reviewable_score_type: PostActionType.types[:illegal])
    end

    it "returns an array of unique flag ids" do
      expect(Flag.used_flag_ids).to eq(
        [
          PostActionType.types[:like],
          PostActionType.types[:off_topic],
          PostActionType.types[:illegal],
        ],
      )
    end
  end
end
