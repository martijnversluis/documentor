class GithubAccount < ApplicationRecord
  encrypts :access_token

  validates :username, presence: true, uniqueness: true
  validates :access_token, presence: true
end
