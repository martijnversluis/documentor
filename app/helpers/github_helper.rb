module GithubHelper
  def notification_icon(type)
    case type
    when "PullRequest" then "pr"
    when "Issue" then "issue"
    when "Release" then "release"
    when "Discussion" then "discussion"
    else "default"
    end
  end

  def reason_label(reason)
    case reason
    when "review_requested" then "review gevraagd"
    when "mention" then "mentioned"
    when "author" then "auteur"
    when "assign" then "toegewezen"
    when "comment" then "reactie"
    when "ci_activity" then "CI"
    when "subscribed" then "watching"
    when "state_change" then "status"
    when "team_mention" then "team mention"
    else reason
    end
  end

  def reason_class(reason)
    case reason
    when "review_requested" then "text-orange-600"
    when "mention", "team_mention" then "text-blue-600"
    when "assign" then "text-purple-600"
    when "author" then "text-green-600"
    else "text-gray-500"
    end
  end
end
