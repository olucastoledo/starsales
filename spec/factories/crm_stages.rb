FactoryBot.define do
  factory :crm_stage do
    crm_pipeline { nil }
    name { "MyString" }
    description { "MyText" }
    position { 1 }
  end
end
