// 서버 norm 테스트(server/test/unit.test.ts)와 기존 BangMusic core.test.cjs 일본어 검색 정규화를 그대로 옮겼다.
import 'package:bangmusic/domain/norm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('가타카나·반각·히라가나 통일', () {
    expect(norm('ｶﾞｰﾙｽﾞ'), 'がーるず');
    expect(norm('ガールズ'), 'がーるず');
    expect(norm('がーるず'), 'がーるず');
  });

  test('전각 영숫자·대소문자·공백', () {
    expect(norm('ＺＥＮＫＡＫＵ  Abc\t１２'), 'zenkaku abc 12');
  });

  test('한자·한글은 그대로', () {
    expect(norm('夜明けのうた'), '夜明けのうた');
    expect(norm('새벽 공기'), '새벽 공기');
  });

  test('core.test.cjs: 반각·가타카나·조합 탁점', () {
    expect(norm('ﾖﾙｼｶ'), norm('よるしか'));
    expect(norm('ガラス'), norm('がらす'));
    expect(norm('ＪＰＯＰ'), 'jpop');
    expect(norm('ガ'), norm('ガ'), reason: '조합 탁점');
  });
}
