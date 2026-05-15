FactoryBot.define do
  factory :crm_deal do
    account { nil }
    crm_stage { nil }
    name { "MyString" }
    description { "MyText" }
    value { "9.99" }
    expected_close_date { "2026-05-14" }
    status { "MyString" }
  end
end
