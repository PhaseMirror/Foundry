//! Automatically checked conformance tests for every registered ID.

use repo_conformance::cases;

macro_rules! test_case {
    ($id:ident, $str:expr) => {
        #[test]
        fn $id() {
            cases::run($str);
        }
    };
}

test_case!(conformance_rp_01, "RP-01");
test_case!(conformance_rp_02, "RP-02");
test_case!(conformance_rp_03, "RP-03");
test_case!(conformance_rp_04, "RP-04");
test_case!(conformance_rp_05, "RP-05");
test_case!(conformance_rp_06, "RP-06");
test_case!(conformance_rp_07, "RP-07");
test_case!(conformance_rp_08, "RP-08");
test_case!(conformance_rp_09, "RP-09");
test_case!(conformance_rp_10, "RP-10");
test_case!(conformance_rp_11, "RP-11");
test_case!(conformance_rp_12, "RP-12");

test_case!(conformance_ft_01, "FT-01");
test_case!(conformance_ft_02, "FT-02");
test_case!(conformance_ft_03, "FT-03");
test_case!(conformance_ft_04, "FT-04");
test_case!(conformance_ft_05, "FT-05");
test_case!(conformance_ft_06, "FT-06");
test_case!(conformance_ft_07, "FT-07");
test_case!(conformance_ft_08, "FT-08");
test_case!(conformance_ft_09, "FT-09");
test_case!(conformance_ft_10, "FT-10");

test_case!(conformance_ho_01, "HO-01");
test_case!(conformance_ho_02, "HO-02");
test_case!(conformance_ho_03, "HO-03");
test_case!(conformance_ho_04, "HO-04");
test_case!(conformance_ho_05, "HO-05");
test_case!(conformance_ho_06, "HO-06");
test_case!(conformance_ho_07, "HO-07");
test_case!(conformance_ho_08, "HO-08");
test_case!(conformance_ho_09, "HO-09");
test_case!(conformance_ho_10, "HO-10");

test_case!(conformance_ct_01, "CT-01");
test_case!(conformance_ct_02, "CT-02");
test_case!(conformance_ct_03, "CT-03");
test_case!(conformance_ct_04, "CT-04");
test_case!(conformance_ct_05, "CT-05");
test_case!(conformance_ct_06, "CT-06");
test_case!(conformance_ct_07, "CT-07");
test_case!(conformance_ct_08, "CT-08");
test_case!(conformance_ct_09, "CT-09");
test_case!(conformance_ct_10, "CT-10");
test_case!(conformance_ct_11, "CT-11");

test_case!(conformance_st_01, "ST-01");
test_case!(conformance_st_02, "ST-02");
test_case!(conformance_st_03, "ST-03");
test_case!(conformance_st_04, "ST-04");
test_case!(conformance_st_05, "ST-05");
test_case!(conformance_st_06, "ST-06");
test_case!(conformance_st_07, "ST-07");
test_case!(conformance_st_08, "ST-08");
test_case!(conformance_st_09, "ST-09");
test_case!(conformance_st_10, "ST-10");

test_case!(conformance_ar_01, "AR-01");
test_case!(conformance_ar_02, "AR-02");
test_case!(conformance_ar_03, "AR-03");
test_case!(conformance_ar_04, "AR-04");
test_case!(conformance_ar_05, "AR-05");
test_case!(conformance_ar_06, "AR-06");
test_case!(conformance_ar_07, "AR-07");
test_case!(conformance_ar_08, "AR-08");
test_case!(conformance_ar_09, "AR-09");
test_case!(conformance_ar_10, "AR-10");

test_case!(conformance_ex_01, "EX-01");
test_case!(conformance_ex_02, "EX-02");
test_case!(conformance_ex_03, "EX-03");
test_case!(conformance_ex_04, "EX-04");
test_case!(conformance_ex_05, "EX-05");
test_case!(conformance_ex_06, "EX-06");
test_case!(conformance_ex_07, "EX-07");
test_case!(conformance_ex_08, "EX-08");
test_case!(conformance_ex_09, "EX-09");
test_case!(conformance_ex_10, "EX-10");

test_case!(conformance_vr_01, "VR-01");
test_case!(conformance_vr_02, "VR-02");
test_case!(conformance_vr_03, "VR-03");
test_case!(conformance_vr_04, "VR-04");
test_case!(conformance_vr_05, "VR-05");
test_case!(conformance_vr_06, "VR-06");
test_case!(conformance_vr_07, "VR-07");
test_case!(conformance_vr_08, "VR-08");
test_case!(conformance_vr_09, "VR-09");
test_case!(conformance_vr_10, "VR-10");
test_case!(conformance_vr_11, "VR-11");
test_case!(conformance_vr_12, "VR-12");

test_case!(conformance_se_01, "SE-01");
test_case!(conformance_se_02, "SE-02");
test_case!(conformance_se_03, "SE-03");
test_case!(conformance_se_04, "SE-04");
test_case!(conformance_se_05, "SE-05");
test_case!(conformance_se_06, "SE-06");
test_case!(conformance_se_07, "SE-07");
test_case!(conformance_se_08, "SE-08");
