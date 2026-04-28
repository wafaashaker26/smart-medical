Map<String, String> symptomTranslation = {
  'itching': 'حكة في الجلد',
  'skin_rash': 'طفح جلدي',
  'nodal_skin_eruptions': 'نتوئات جلدية عقدية',
  'continuous_sneezing': 'عطس مستمر',
  'shivering': 'قشعريرة / رعشة',
  'chills': 'برودة في الجسم',
  'joint_pain': 'ألم في المفاصل',
  'stomach_pain': 'ألم في المعدة',
  'acidity': 'حموضة / حرقان معدة',
  'ulcers_on_tongue': 'تقرحات في اللسان',
  'muscle_wasting': 'ضمور في العضلات',
  'vomiting': 'قيء / ترجيع',
  'burning_micturition': 'حرقان أثناء التبول',
  'spotting_urination': 'تنقيط في البول',
  'fatigue': 'إرهاق وتعب عام',
  'weight_gain': 'زيادة في الوزن',
  'anxiety': 'قلق وتوتر',
  'cold_hands_and_feets': 'برودة الأطراف',
  'mood_swings': 'تقلبات مزاجية',
  'weight_loss': 'فقدان في الوزن',
  'restlessness': 'عدم راحة / تململ',
  'lethargy': 'خمول / كسل شديد',
  'patches_in_throat': 'بقع في الحلق',
  'irregular_sugar_level': 'اضطراب مستوى السكر',
  'cough': 'سعال / كحة',
  'high_fever': 'حمى شديدة',
  'sunken_eyes': 'جحوظ / غوران العين',
  'breathlessness': 'ضيق في التنفس',
  'sweating': 'تعرق زائد',
  'dehydration': 'جفاف',
  'indigestion': 'عسر هضم',
  'headache': 'صداع',
  'yellowish_skin': 'اصفرار الجلد',
  'dark_urine': 'بول داكن',
  'nausea': 'غثيان / نفس غمة',
  'loss_of_appetite': 'فقدان شهية',
  'pain_behind_the_eyes': 'ألم خلف العينين',
  'back_pain': 'ألم في الظهر',
  'constipation': 'إمساك',
  'abdominal_pain': 'ألم في البطن',
  'diarrhoea': 'إسهال',
  'mild_fever': 'حمى خفيفة',
  'yellow_urine': 'بول أصفر فاقع',
  'yellowing_of_eyes': 'اصفرار العين',
  'acute_liver_failure': 'فشل كبدي حاد',
  'fluid_overload': 'احتباس سوائل',
  'swelling_of_stomach': 'تورم في المعدة',
  'swelled_lymph_nodes': 'تورم الغدد اللمفاوية',
  'malaise': 'وعكة صحية عامة',
  'blurred_and_distorted_vision': 'تشوش الرؤية',
  'phlegm': 'بلغم',
  'throat_irritation': 'تهيج الحلق',
  'redness_of_eyes': 'احمرار العين',
  'sinus_pressure': 'ضغط في الجيوب الأنفية',
  'runny_nose': 'رشح الأنف',
  'congestion': 'احتقان',
  'chest_pain': 'ألم في الصدر',
  'weakness_in_limbs': 'ضعف في الأطراف',
  'fast_heart_rate': 'سرعة ضربات القلب',
  'pain_during_bowel_movements': 'ألم أثناء التبرز',
  'pain_in_anal_region': 'ألم في منطقة الشرج',
  'bloody_stool': 'براز مدمم',
  'irritation_in_anus': 'تهيج في الشرج',
  'neck_pain': 'ألم في الرقبة',
  'dizziness': 'دوخة / دوار',
  'cramps': 'تشنجات / مغص',
  'bruising': 'كدمات',
  'obesity': 'سمنة مفرطة',
  'swollen_legs': 'تورم الساقين',
  'swollen_blood_vessels': 'تورم الأوعية الدموية',
  'puffy_face_and_eyes': 'انتفاخ الوجه والعينين',
  'enlarged_thyroid': 'تضخم الغدة الدرقية',
  'brittle_nails': 'أظافر هشة',
  'swollen_extremeties': 'تورم الأطراف',
  'excessive_hunger': 'جوع مفرط',
  'extra_marital_contacts': 'علاقات خارجية (سياق طبي)',
  'drying_and_tingling_lips': 'جفاف ووخز الشفاة',
  'slurred_speech': 'تأتأة / صعوبة النطق',
  'knee_pain': 'ألم الركبة',
  'hip_joint_pain': 'ألم مفصل الورك',
  'muscle_weakness': 'ضعف العضلات',
  'stiff_neck': 'تصلب الرقبة',
  'swelling_joints': 'تورم المفاصل',
  'movement_stiffness': 'صعوبة في الحركة',
  'spinning_movements': 'شعور بالدوار (لف)',
  'loss_of_balance': 'فقدان التوازن',
  'unsteadiness': 'عدم اتزان',
  'weakness_of_one_body_side': 'ضعف في جانب واحد من الجسم',
  'loss_of_smell': 'فقدان حاسة الشم',
  'bladder_discomfort': 'عدم راحة في المثانة',
  'foul_smell_ofurine': 'رائحة بول كريهة',
  'continuous_feel_of_urine': 'شعور مستمر بالتبول',
  'passage_of_gases': 'خروج غازات',
  'internal_itching': 'حكة داخلية',
  'toxic_look_(typhos)': 'شحوب شديد (مظهر تسممي)',
  'depression': 'اكتئاب / حزن شديد',
  'irritability': 'سرعة الانفعال',
  'muscle_pain': 'ألم العضلات',
  'altered_sensorium': 'تغير في الحالة الإدراكية',
  'red_spots_over_body': 'بقع حمراء على الجسم',
  'belly_pain': 'ألم في منطقة الصرة',
  'abnormal_menstruation': 'اضطراب الدورة الشهرية',
  'dischromic_patches': 'بقع متغيرة اللون',
  'watering_from_eyes': 'تدميع العين',
  'increased_appetite': 'زيادة الشهية',
  'polyuria': 'كثرة التبول',
  'family_history': 'تاريخ عائلي للمرض',
  'mucoid_sputum': 'بلغم مخاطي',
  'rusty_sputum': 'بلغم بلون صدئي',
  'lack_of_concentration': 'ضعف التركيز',
  'visual_disturbances': 'اضطرابات بصرية',
  'receiving_blood_transfusion': 'نقل دم سابق',
  'receiving_unsterile_injections': 'حقن غير معقمة',
  'coma': 'غيبوبة',
  'stomach_bleeding': 'نزيف في المعدة',
  'distention_of_abdomen': 'انتفاخ البطن',
  'history_of_alcohol_consumption': 'تاريخ شرب كحوليات',
  'blood_in_sputum': 'دم في البلغم',
  'prominent_veins_on_calf': 'عروق بارزة في الساق',
  'palpitations': 'خفقان القلب',
  'painful_walking': 'ألم أثناء المشي',
  'pus_filled_pimples': 'بثور مليئة بالصديد',
  'blackheads': 'رؤوس سوداء',
  'scurring': 'ندبات جلدية',
  'skin_peeling': 'تقشير الجلد',
  'silver_like_dusting': 'قشور فضية',
  'small_dents_in_nails': 'حفر صغيرة في الأظافر',
  'inflammatory_nails': 'التهاب الأظافر',
  'blister': 'فقاعة جلدية',
  'red_sore_around_nose': 'قرح حمراء حول الأنف',
  'yellow_crust_ooze': 'إفرازات قشرية صفراء',
};

String getEnglishSymptom(String arabicName) {
  try {
    return symptomTranslation.entries
        .firstWhere((element) => element.value.trim() == arabicName.trim())
        .key;
  } catch (e) {
    return arabicName;
  }
}

class DiseaseProba {
  final String disease;
  final double probability;

  DiseaseProba({required this.disease, required this.probability});

  factory DiseaseProba.fromJson(Map<String, dynamic> j) =>
      DiseaseProba(
        disease: j['disease'],
        probability: (j['probability'] as num).toDouble(),
      );
}

class PredictionResult {
  final String disease;
  final String riskLevel;
  final int riskScore;
  final List<DiseaseProba> probabilities;
  final List<String> explanation;
  final String aiSummary;

  PredictionResult({
    required this.disease,
    required this.riskLevel,
    required this.riskScore,
    required this.probabilities,
    required this.explanation,
    required this.aiSummary,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> j) =>
      PredictionResult(
        disease: j['disease'],
        riskLevel: j['risk_level'],
        riskScore: j['risk_score'],
        probabilities: (j['probabilities'] as List)
            .map((e) => DiseaseProba.fromJson(e))
            .toList(),
        explanation: List<String>.from(j['explanation']),
        aiSummary: j['ai_summary'] ?? '',
      );
}